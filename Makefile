start:
	bash pre_install.sh
	bash run_gochain.sh start
	bash post_install.sh setup
setup:
	bash post_install.sh setup
run:
	bash pre_install.sh
	bash run_gochain.sh start
test-btp:
	bash post_install.sh sendBTPMessage
ibc-ready:
	bash pre_install.sh
	bash run_gochain.sh start
	bash post_install.sh cfg
ibc-ready-multi:
	bash pre_install.sh
	bash run_gochain.sh start
	bash post_install.sh multi
stop:
	bash run_gochain.sh stop