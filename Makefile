start:
	./pre_install.sh
	./run_gochain.sh start
	./post_install.sh setup

test-btp:
	./post_install.sh sendBTPMessage

stop:
	./run_gochain.sh stop