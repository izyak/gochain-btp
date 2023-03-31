start:
	bash pre_install.sh
	bash run_gochain.sh start
	bash post_install.sh setup
run:
	bash pre_install.sh
	bash run_gochain.sh start
test-btp:
	bash post_install.sh sendBTPMessage

stop:
	bash run_gochain.sh stop