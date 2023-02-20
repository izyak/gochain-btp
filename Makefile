start:
	./pre_install.sh
	./run_gochain.sh start
	./post_install.sh

stop:
	./run_gochain.sh stop