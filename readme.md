# 安装工具

## 安装 HTK

到官方注册后下载源码包和《The HTK Book》。

如果是 macOS：

```bash
ln -s /opt/X11/include/X11 /usr/local/include/X11
export LIBRARY_PATH="/opt/X11:/opt/X11/lib"
```

编译：

```bash
tar xvf HTK-3.4.1.tar.gz
cd htk
./configure --prefix=`pwd`
make all
make install
```

设置环境变量：

```bash
export PATH=`pwd`/bin:$PATH
```

## 安装 Julius

在 macOS 平台从源码编译需要一些依赖包，用 brew 安装则可以自动解决依赖：

```bash
brew install julius
```

## 安装 Julia

```
brew cask install julia
```

## 安装 Audacity

macOS 平台到[官网](http://www.audacityteam.org/download/mac/)下载安装包后手动安装。

## 验证

执行如下命令应该输出正常软件信息：

```
HVite -V
julius
julia -v
```



# 语音拨号

## 任务语法

创建 `sample.grammar` 文件：

```
S : NS_B SENT NS_E
SENT: CALL_V NAME_N
SENT: DIAL_V DIGIT
```

创建 `sample.voca` 文件：

```
% NS_B
<s>        sil

% NS_E
</s>        sil

% CALL_V
PHONE        f ow n
CALL        k ao l

% DIAL_V
DIAL        d ay ah l

% NAME_N
STEVE        s t iy v
YOUNG        y ah ng

% DIGIT
FIVE        f ay v
FOUR        f ao r
NINE        n ay n
EIGHT        ey t
OH        ow
ONE        w ah n
SEVEN        s eh v ah n
SIX        s ih k s
THREE        th r iy
TWO        t uw
ZERO        z iy r ow
```

上面两个文件的名字必须相同（仅后缀不同），然后执行：

```
mkdfa.pl sample
```

生成 `sample.dfa`、`sample.term`、`sample.dict`三个文件。

前两个文件描述了一个有限自动机，最后一个是描述单词发音的字典。

## 发音字典

创建 `prompts.txt`：

```
*/S001 DIAL ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE OH ZERO
*/S002 DIAL ONE THREE FIVE SEVEN NINE ZERO TWO FOUR SIX EIGHT OH
*/S003 DIAL ZERO NINE SEVEN FIVE THREE ONE OH EIGHT SIX FOUR TWO
*/S004 DIAL ONE ONE TWO TWO THREE THREE FOUR FOUR FIVE FIVE
*/S005 DIAL SIX SIX SEVEN SEVEN EIGHT EIGHT NINE NINE OH OH ZERO ZERO
*/S006 PHONE STEVE YOUNG CALL STEVE YOUNG
*/S007 PHONE STEVE CALL STEVE PHONE YOUNG CALL YOUNG
*/S008 PHONE PHONE STEVE STEVE  CALL CALL YOUNG YOUNG
*/S009 MEASURE LEISURE AND LEISURE MEASURE
*/S010 COMPLAIN CHAMPLAIN AIRPLANE ELAINE EXPLAIN
*/S011 BOOKENDS KENNEL KENNETH KENYA WEEKEND
*/S012 BELT BELOW BEND AEROBIC DASHBOARD DATABASE
*/S013 GATEWAY GATORADE GAZEBO AFGHAN AGAINST AGATHA
*/S014 ABALON ABDOMINALS BODY ABOLISH
*/S015 ABOUNDING ABOUT ACCOUNT ALLENTOWN
*/S016 ACHIEVE ACTUAL ACUPUNCTURE ADVENTURE
*/S017 ALGORITHM ALTHOUGH ALTOGETHER ANOTHER
*/S018 BATTLE BEATLE LITTLE METAL
*/S019 BITTEN BLATANT BRIGHTEN BRITAIN
*/S020 BROOKHAVEN HOOD BROUHAHA BULLHEADS
*/S021 BUSBOYS CHOICE COILS COIN
*/S022 COLLECTION COLORATION COMBINATION COMMERCIAL
*/S023 MIDDLE NEEDLE POODLE SADDLE
*/S024 ALRIGHT ARTHRITIS BRIGHT COPYRIGHT CRITERIA RIGHT
*/S025 COUPLE CRADLE CRUMBLE
*/S026 CUBA CUBE CUMULATIVE
*/S027 CURING CURLING CYCLING
*/S028 CYNTHIA DANFORTH DEPTH
*/S029 DIGEST DIGITAL DILIGENT
*/S030 AMNESIA ASIA AVERSION BEIGE BEIJING
*/S031 HELP HELLO HELMET HELPLESS AHEAD HELP
*/S032 VOXFORGE HOME READ LISTEN FORUMS DEVELOPER ABOUT HOWTO TUTORIAL
*/S033 RHYTHMBOX PLAY START NEXT SKIP FORWARD PREVIOUS BACK
*/S034 MUSIC SHOW WHO ABOUT INFORMATION UP LOUDER DOWN LOWER
*/S035 PLAYER SOFTER SILENCE STOP QUIET
*/S036 COMPUTER WEATHER EMAIL VOLUME LOUDER SOFTER
*/S037 COMPUTERIZE AMPUTATE MINICOMPUTER PUMA'S PEWTER   
*/S038 ACUTE AMPUTATION BOOTERS CONTRIBUTOR'S ALOUETTE GIFTWARE GLADWELL
*/S039 MAYWEATHER WHETHER WOODSTREAM ARTILLERYMAN CREMATION DAIRYMAID FEMALE
*/S040 ISHMAEL'S LANCEDALE LAVAL VOLATILE SCALIA SOLUBLE SUPERVALUE VALUATION
```

执行如下命令（脚本在 `HTK-samples-3.4.1.tar.gz` 包里面）可将上面文件中的单词排序并去重，每行一个单词：

```
samples/HTKTutorial/prompts2wlist prompts.txt wlist
```

生成文件 `wlist`，并自动插入如下内容，它们是 HTK 用于创建声学模型的内部条目：

```
SENT-END 
SENT-START
```

创建工具 `HDMan` 的默认脚本 `global.ded`，其主要作用是把单词转大写：

```
AS sp
RS cmu
MP sil sil sp
```

执行命令：

```
wget https://raw.githubusercontent.com/VoxForge/develop/master/lexicon/VoxForgeDict.txt
HDMan -A -D -T 1 -m -w wlist -n monophones1 -i -l dlog dict VoxForgeDict.txt
```

生成发音字典文件 `dict`，其中会用到的音素在 `monophones1` 文件中，`dlog` 是日志。

然后，将 `monophones1` 复制一份为 `monophones0`，并将后者中的 `sp` 行删除。

## 记录数据

设置 `Audacity` 如下，然后重启生效：

```
Audacity -> Preferences... -> Quality -> Default Sample Rate -> 16000 HZ
Audacity -> Preferences... -> Quality -> Default Sample Format -> 16-bit
Audacity -> Preferences... -> Devices -> Recording -> Channels -> 1(Mono)
```

为 `prompts.txt` 中的文本录音。每行对应一个音频文件，第一列是文件名。

比如第一个文件 `S001.wav` 的录音内容为：

```
DIAL ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE OH ZERO
```

波形应该在 -1.0~1.0 之间。

保存时选择：

```
File -> Export -> Export as WAV
```

## 创建转录文件

生成 `words.mlf` 文件（注意参数顺序）：

```
samples/HTKTutorial/prompts2mlf words.mlf prompts.txt
```

创建 `mkphones0.led` 文件（注意以空行结尾）：

```
EX
IS sil sil
DE sp

```

生成 `phones0.mlf` 文件：

```
HLEd -A -D -T 1 -l '*' -d dict -i phones0.mlf mkphones0.led words.mlf
```

创建文件 `mkphones1.led`（注意以空行结尾）：

```
EX
IS sil sil

```

生成 `phones1.mlf` 文件（每个单词结尾会多一个 "sp" - short pause）：

```
HLEd -A -D -T 1 -l '*' -d dict -i phones1.mlf mkphones1.led words.mlf
```

## 音频数据编码

创建文件 `codetrain.scp`：

```
./wav/S001.wav ./mfcc/S001.mfc
./wav/S002.wav ./mfcc/S002.mfc
./wav/S003.wav ./mfcc/S003.mfc
./wav/S004.wav ./mfcc/S004.mfc
./wav/S005.wav ./mfcc/S005.mfc
./wav/S006.wav ./mfcc/S006.mfc
./wav/S007.wav ./mfcc/S007.mfc
./wav/S008.wav ./mfcc/S008.mfc
./wav/S009.wav ./mfcc/S009.mfc
./wav/S010.wav ./mfcc/S010.mfc
./wav/S011.wav ./mfcc/S011.mfc
./wav/S012.wav ./mfcc/S012.mfc
./wav/S013.wav ./mfcc/S013.mfc
./wav/S014.wav ./mfcc/S014.mfc
./wav/S015.wav ./mfcc/S015.mfc
./wav/S016.wav ./mfcc/S016.mfc
./wav/S017.wav ./mfcc/S017.mfc
./wav/S018.wav ./mfcc/S018.mfc
./wav/S019.wav ./mfcc/S019.mfc
./wav/S020.wav ./mfcc/S020.mfc
./wav/S021.wav ./mfcc/S021.mfc
./wav/S022.wav ./mfcc/S022.mfc
./wav/S023.wav ./mfcc/S023.mfc
./wav/S024.wav ./mfcc/S024.mfc
./wav/S025.wav ./mfcc/S025.mfc
./wav/S026.wav ./mfcc/S026.mfc
./wav/S027.wav ./mfcc/S027.mfc
./wav/S028.wav ./mfcc/S028.mfc
./wav/S029.wav ./mfcc/S029.mfc
./wav/S030.wav ./mfcc/S030.mfc
./wav/S031.wav ./mfcc/S031.mfc
./wav/S032.wav ./mfcc/S032.mfc
./wav/S033.wav ./mfcc/S033.mfc
./wav/S034.wav ./mfcc/S034.mfc
./wav/S035.wav ./mfcc/S035.mfc
./wav/S036.wav ./mfcc/S036.mfc
./wav/S037.wav ./mfcc/S037.mfc
./wav/S038.wav ./mfcc/S038.mfc
./wav/S039.wav ./mfcc/S039.mfc
./wav/S040.wav ./mfcc/S040.mfc
```

创建文件 `wav_config`：

```
SOURCEFORMAT = WAV
TARGETKIND = MFCC_0_D
TARGETRATE = 100000.0
SAVECOMPRESSED = T
SAVEWITHCRC = T
WINDOWSIZE = 250000.0
USEHAMMING = T
PREEMCOEF = 0.97
NUMCHANS = 26
CEPLIFTER = 22
NUMCEPS = 12
```

生成 MFCC 格式的文件（里面都是特征向量）：

```
mkdir mfcc
HCopy -A -D -T 1 -C wav_config -S codetrain.scp
```

## Monophones

创建文件 `proto`：

```
~o <VecSize> 25 <MFCC_0_D_N_Z>
~h "proto"
<BeginHMM>
  <NumStates> 5
  <State> 2
    <Mean> 25
      0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  
    <Variance> 25
      1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 
 <State> 3
    <Mean> 25
      0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  
    <Variance> 25
      1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
 <State> 4
    <Mean> 25
      0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 
    <Variance> 25
      1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
 <TransP> 5
  0.0 1.0 0.0 0.0 0.0
  0.0 0.6 0.4 0.0 0.0
  0.0 0.0 0.6 0.4 0.0
  0.0 0.0 0.0 0.7 0.3
  0.0 0.0 0.0 0.0 0.0
<EndHMM>

```

创建文件 `config`：

```
TARGETKIND = MFCC_0_D_N_Z
TARGETRATE = 100000.0
SAVECOMPRESSED = T
SAVEWITHCRC = T
WINDOWSIZE = 250000.0
USEHAMMING = T
PREEMCOEF = 0.97
NUMCHANS = 26
CEPLIFTER = 22
NUMCEPS = 12 
```

注意，上面两个文件中的 `MFCC_0_D_N_Z` 是相匹配的。

创建文件 `train.scp`：

```
./mfcc/S001.mfc
./mfcc/S002.mfc
./mfcc/S003.mfc
./mfcc/S004.mfc
./mfcc/S005.mfc
./mfcc/S006.mfc
./mfcc/S007.mfc
./mfcc/S008.mfc
./mfcc/S009.mfc
./mfcc/S010.mfc
./mfcc/S011.mfc
./mfcc/S012.mfc
./mfcc/S013.mfc
./mfcc/S014.mfc
./mfcc/S015.mfc
./mfcc/S016.mfc
./mfcc/S017.mfc
./mfcc/S018.mfc
./mfcc/S019.mfc
./mfcc/S020.mfc
./mfcc/S021.mfc
./mfcc/S022.mfc
./mfcc/S023.mfc
./mfcc/S024.mfc
./mfcc/S025.mfc
./mfcc/S026.mfc
./mfcc/S027.mfc
./mfcc/S028.mfc
./mfcc/S029.mfc
./mfcc/S030.mfc
./mfcc/S031.mfc
./mfcc/S032.mfc
./mfcc/S033.mfc
./mfcc/S034.mfc
./mfcc/S035.mfc
./mfcc/S036.mfc
./mfcc/S037.mfc
./mfcc/S038.mfc
./mfcc/S039.mfc
./mfcc/S040.mfc
```

创建新模型：

```
mkdir hmm0
HCompV -A -D -T 1 -C config -f 0.01 -m -S train.scp -M hmm0 proto
```

在 `hmm0` 目录下生成文件 `proto` 和 `vFloors`。

执行如下脚本生成文件 `hmm0/hmmdefs`：

```bash
text="$(sed -n '/<BEGINHMM>/,/<ENDHMM>/'p hmm0/proto)"
for ln in `cat monophones0`; do echo -e "~h \"${ln}\"\n${text}" >> hmm0/hmmdefs; done
```

它将 `monophones0` 中的每个音素变成 `~h "x"` 形式，然后在每行后面追加 `hmm0/proto` 文件中的 `<BEGINHMM>...<ENDHMM>` 部分的内容。看起来如下：

```
~h "ae"
<BEGINHMM>
...
<ENDHMM>
~h "b"
<BEGINHMM>
...
<ENDHMM>
...
```

执行如下脚本生成文件 `macros`：

```bash
head -n3 hmm0/proto > hmm0/macros
cat hmm0/vFloors >> hmm0/macros
```

它看起来如下：

```
~o
<STREAMINFO> 1 25
<VECSIZE> 25<NULLD><MFCC_D_N_Z_0><DIAGC>
~v varFloor1
<Variance> 25
 5.294691e-01 4.963992e-01 4.432231e-01 7.569560e-01 6.260971e-01 5.816380e-01 3.991303e-01 5.058298e-01 4.723607e-01 3.758217e-01 2.628475e-01 3.142200e-01 1.848056e-02 1.592366e-02 1.743356e-02 2.282314e-02 2.269823e-02 2.684780e-02 2.440277e-02 2.933924e-02 2.493926e-02 2.308038e-02 2.002368e-02 1.925660e-02 2.247548e-02
```

然后，重复估计：

```bash
for n in {1..9}; do mkdir hmm${n}; done
for n in {0..2}; do HERest -A -D -T 1 -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm${n}/macros -H hmm${n}/hmmdefs -M hmm$((n+1)) monophones0; done
```

## Fixing the Silence Models

```
cp hmm3/* hmm4
```

将 `hmm4/hmmdefs` 中最后的一块 `sil` 的内容复制一份并追加在最后，删除 `<STATE> 2` 至 `<STATE> 4` 之间的内容，然后剩下的行做相应修改如下（包括替换矩阵内容）：

```
~h "sp"
<NUMSTATES> 3
<STATE> 2
<TRANSP> 3
 0.0 1.0 0.0
 0.0 0.9 0.1
 0.0 0.0 0.0
```

创建文件 `sil.hed`：

```
AT 2 4 0.2 {sil.transP}
AT 4 2 0.2 {sil.transP}
AT 1 3 0.3 {sp.transP}
TI silst {sil.state[3],sp.state[2]}
```

执行如下命令：

```bash
HHEd -A -D -T 1 -H hmm4/macros -H hmm4/hmmdefs -M hmm5 sil.hed monophones1
HERest -A -D -T 1 -C config  -I phones1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm5/macros -H  hmm5/hmmdefs -M hmm6 monophones1
HERest -A -D -T 1 -C config  -I phones1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm6/macros -H hmm6/hmmdefs -M hmm7 monophones1
```

## Realigning the Training Data

执行如下命令：

```
HVite -A -D -T 1 -l '*' -o SWT -b SENT-END -C config -H hmm7/macros -H hmm7/hmmdefs -i aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I words.mlf -S train.scp dict monophones1> HVite_log
```

生成文件 `aligned.mlf`。确认一下日志 `HVite_log` 中是否有出错信息。

执行如下命令：

```bash
HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm7/macros -H hmm7/hmmdefs -M hmm8 monophones1 
HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm8/macros -H hmm8/hmmdefs -M hmm9 monophones1
```

## Making Triphones from Monophones

创建文件 `mktri.led`：

```
WB sp
WB sil
TC

```

执行如下命令，将创建两个包含三音素的文件 `wintri.mlf` 和 `triphones1`：

```
HLEd -A -D -T 1 -n triphones1 -l '*' -i wintri.mlf mktri.led aligned.mlf
```

执行如下命令，生成文件 `mktri.hed`：

```
samples/HTKTutorial/maketrihed monophones1 triphones1
```

执行如下命令：

```bash
for n in {10..12}; do mkdir hmm${n}; done
HHEd -A -D -T 1 -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1
HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm10/macros -H hmm10/hmmdefs -M hmm11 triphones1
HERest  -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -s stats -S train.scp -H hmm11/macros -H hmm11/hmmdefs -M hmm12 triphones1
```

> `WARNING [-2331]` 表示训练数据不够多，可以忽略它。
>
> 执行最后一条命令会在当前目录下生成文件 `stats`，后面会用到。

## Making Tied-State Triphones

创建文件 `maketriphones.ded`：

```
AS sp
MP sil sil sp
TC
```

执行如下命令，将生成三个文件 `fulllist0`、`flog`、`dict-tri`：

```
HDMan -A -D -T 1 -b sp -n fulllist0 -g maketriphones.ded -l flog dict-tri VoxForgeDict.txt
```

执行如下命令，将 `monophones0` 追加到 `fulllist0` 并去重（实际对比结果为追加，并无重复行）：

```
wget https://raw.githubusercontent.com/VoxForge/develop/master/bin/fixfulllist.jl
julia fixfulllist.jl fulllist0 monophones0 fulllist
```

执行如下命令：

```
wget https://raw.githubusercontent.com/VoxForge/develop/master/tutorial/tree1.hed
cp tree1.hed tree.hed
wget https://raw.githubusercontent.com/VoxForge/develop/master/bin/mkclscript.jl
julia mkclscript.jl monophones0 tree.hed
```

> `tree1.hed` 文件格式：
>
> - RO - outlier threshhold
>
> - 1st "TR" - trace level
>
> - QS - question - defined by the user (see quests.hed file in HTK distribution - RM demo folder)
>
>   (each QS command loads a single question and that question is defined by a set of contexts)
>
> - 2nd "TR" - enables intermediate level progress reporting
>
> - TB - clusters one specific set of states - created with the mkclscript.prl command
>
> - AU - synthesize previously unseen triphones, i.e. use the set of newly created decision trees to make all the triphones included in the list
>
> - CO - compact the model set: some state definitions will be exactly the same (same means and variances etc.). To save space, only one of these states is kept in the definition, others are added to the tiedlist.
>
> - ST - save the decision trees in a file

检查文件 `tree.hed` 的末尾应该会看到如下内容：

```
TR 1

AU "./fulllist" 
CO "./tiedlist" 

ST "./trees" 
```

执行如下命令：

```bash
for n in {13..15}; do mkdir hmm${n}; done
HHEd -A -D -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm13/macros -H hmm13/hmmdefs -M hmm14 tiedlist
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm14/macros -H hmm14/hmmdefs -M hmm15 tiedlist
```

> 执行 `HHEd` 命令会生成三个文件：`hmm13/hmmdefs`、`hmm13/macros`、`tiedlist`。
>
> 执行 `HERest` 命令会生成两个文件：`hmmN/hmmdefs`、`hmmN/macros`。

## Running Julius Live

创建配置文件 `sample.jconf`：

```julia
#
# Sample Jconf configuration file
# for Julius library rev.4.3
######################################################################

####
#### misc.
####
# !!!!!! VoxForge change
#-outprobout filename		# save computed outprob vectors to HTK file (for debug)
# !!!!!! 

# VoxForge configurations:
-dfa sample.dfa     # finite state automaton grammar file
-v sample.dict      # pronunciation dictionary
-h hmm15/hmmdefs    # acoustic HMM (ascii or Julius binary)
-hlist tiedlist     # HMMList to map logical phone to physical
-smpFreq 16000	    # sampling rate (Hz)
-spmodel "sp"		    # name of a short-pause silence model
-multipath          # force enable MULTI-PATH model handling
-gprune safe        # Gaussian pruning method
-iwcd1 max          # Inter-word triphone approximation method
-iwsppenalty -70.0	# transition penalty for the appended sp models
-iwsp			          # append a skippable sp model at all word ends
-penalty1 5.0		    # word insertion penalty for grammar (pass1)
-penalty2 20.0	    # word insertion penalty for grammar (pass2)
-b2 200             # beam width on 2nd pass (#words)
-sb 200.0		        # score beam envelope threshold
-n 1                # num of sentences to find

# you may need to adjust your "-lv" value to prevent the recognizer inadvertently 
# recognizing non-speech sounds:
-lv 4000			# level threshold (0-32767)

# comment these out for debugging:
-logfile julius.log
-quiet
# !!!!!!
```

执行：

```
julius -input mic -C sample.jconf
```

提示后用麦克风语音拨号，显示如下：

```
STAT: include config: sample.jconf
<<< please speak >>>
pass1_best: <s> CALL STEVE
sentence1: <s> CALL STEVE </s>
<<< please speak >>>
pass1_best: <s> CALL
sentence1: <s> CALL YOUNG </s>
<<< please speak >>>
pass1_best: <s> DIAL ONE
sentence1: <s> DIAL ONE </s>
<<< please speak >>>
```

运行细节查看日志 `julius.log`。



# Troubleshooting

### [macOS] 'X11/Xlib.h' file not found

```bash
ln -s /opt/X11/include/X11 /usr/local/include/X11
```

### [macOS] 'malloc.h' file not found

修改 `HTKLib/strarr.c`：

```c
//#include <malloc.h>
#include <stdlib.h>
```

### [macOS] not found for option '-L/usr/X11R6/lib'

```bash
export LIBRARY_PATH="/opt/X11/:/opt/X11/lib"
```

### CreateInsts: Unknown label sil

如果 `monophones1` 中的最后一行不是 `sil`，可能是 `wlist` 中没有加入：

```
SENT-END 
SENT-START
```

然后重新生成 `monophones1` 和 `dict`。

最后，`hmmdefs` 也要重新生成。

### Unable to open label file ./mfcc/S001.lab

文件 `prompts.txt` 的每行开头必须包含 `*/`：

```
*/S001
```

然后，修改后相关文件必须全部重新生成。

### LatticeFromLabels: Word SENT-END not defined in dictionary

`wlist` 文件中需要手动加入：

```
SENT-END 
SENT-START
```

注意排序。

### ApplyTie: Macro T_sil has nothing to tie of type t in HHEd

警告，没关系。

"When running the HHEd command you will get warnings about trying to tie transition matrices for the sil an sp models. Since neither model is context-dependet there aren't actually any matrices to tie"——《HTK-Book》。



# 参考

- [Tutorial: Create Acoustic Model - Manually](http://www.voxforge.org/home/dev/acousticmodels/linux/create/htkjulius/tutorial)

