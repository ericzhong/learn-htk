#!/bin/bash

mkdfa.pl sample

./prompts2wlist prompts.txt wlist.tmp
echo -e "SENT-END\nSENT-START" >> wlist.tmp
sort wlist.tmp > wlist
rm wlist.tmp

HDMan -m -w wlist -n monophones1 -i -l dlog dict VoxForgeDict.txt
cp monophones1 monophones0
sed -i "" '/^sp$/d' monophones0

# HSGen -l -n 40 wdnet dict > testprompts.txt

./prompts2mlf words.mlf prompts.txt

HLEd -l '*' -d dict -i phones0.mlf mkphones0.led words.mlf
HLEd -l '*' -d dict -i phones1.mlf mkphones1.led words.mlf

mkdir train
HCopy -C wav_config -S codetrain.scp

mkdir hmm0
HCompV -C config -f 0.01 -m -S train.scp -M hmm0 proto

text="$(sed -n '/<BEGINHMM>/,/<ENDHMM>/'p hmm0/proto)"
for ln in `cat monophones0` sil; do echo -e "~h \"${ln}\"\n${text}" >> hmm0/hmmdefs; done
head -n3 hmm0/proto > hmm0/macros
cat hmm0/vFloors >> hmm0/macros

mkdir hmm1 hmm2 hmm3
HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm0/macros -H hmm0/hmmdefs -M hmm1 monophones0
HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm1/macros -H hmm1/hmmdefs -M hmm2 monophones0
HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm2/macros -H hmm2/hmmdefs -M hmm3 monophones0

mkdir hmm4
cp hmm3/* hmm4
./makesp hmm4/hmmdefs >> hmm4/hmmdefs

mkdir hmm5 hmm6 hmm7
HHEd -H hmm4/macros -H hmm4/hmmdefs -M hmm5 sil.hed monophones1
HERest -C config  -I phones1.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm5/macros -H  hmm5/hmmdefs -M hmm6 monophones1
HERest -C config  -I phones1.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm6/macros -H hmm6/hmmdefs -M hmm7 monophones1

HVite -l '*' -o SWT -b SENT-END -C config -a -H hmm7/macros -H hmm7/hmmdefs -i aligned.mlf -m -t 250.0 -y lab -I words.mlf -S train.scp dict monophones1

mkdir hmm8 hmm9
HERest -C config  -I phones1.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm7/macros -H  hmm7/hmmdefs -M hmm8 monophones1
HERest -C config  -I phones1.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm8/macros -H hmm8/hmmdefs -M hmm9 monophones1

HLEd -n triphones1 -l '*' -i wintri.mlf mktri.led aligned.mlf
./maketrihed monophones1 triphones1

mkdir hmm10
HHEd -B -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1

mkdir hmm11 hmm12
HERest -C config  -I wintri.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm10/macros -H  hmm10/hmmdefs -M hmm11 triphones1
HERest -C config  -I wintri.mlf -t 250.0 150.0 1000.0 -s stats -S train.scp -H hmm11/macros -H  hmm11/hmmdefs -M hmm12 triphones1

echo -e 'RO 100 "stats"\nTR 0\n' > tree.hed
cat quests.hed >> tree.hed
echo -e '\nTR 2\n' >> tree.hed
./mkclscript TB 350 monophones0 >> tree.hed
echo -e '\nTR 1\n\nAU "./fulllist"\nCO "./tiedlist"\n\nST "./trees"' >> tree.hed

mkdir hmm13 hmm14 hmm15
HDMan -b sp -n fulllist -g maketriphones.ded -l flog dict-tri VoxForgeDict.txt
for p in `cat monophones0`; do grep "^${p}$" fulllist > /dev/null; [ $? -eq 1 ] && echo $p >> fulllist; done
HHEd -B -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1 
HERest -C config -I wintri.mlf  -t 250.0 150.0 1000.0 -S train.scp -H hmm13/macros -H hmm13/hmmdefs -M hmm14 tiedlist
HERest -C config -I wintri.mlf  -t 250.0 150.0 1000.0 -S train.scp -H hmm14/macros -H hmm14/hmmdefs -M hmm15 tiedlist

julius -input mic -C sample.jconf

