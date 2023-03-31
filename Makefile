start:
	sh pre_install.sh
	sh run_gochain.sh start
	sh post_install.sh setup

test-btp:
	sh post_install.sh sendBTPMessage

stop:
	sh run_gochain.sh stop