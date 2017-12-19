
build:
	./build.sh

run:
	julius -input mic -C sample.jconf

clean:
	rm -rf aligned.mlf hmm* dict dict-tri dlog
	rm -rf fulllist monophones* phones*.mlf
	rm -rf stats testprompts.txt tiedlist trees
	rm -rf triphones1 wdnet wintri.mlf wlist words.mlf
	rm -rf train flog julius.log
	rm -rf sample.{dfa,term,dict}
