start:
	bash pre_install.sh
	bash run_gochain.sh start
	chmod +x ./goloop
	bash post_install.sh setup


test-btp:
	sh post_install.sh sendBTPMessage

stop:
	sh run_gochain.sh stop