start:
	bash run_gochain.sh start
	bash post_install.sh setup
run:
	bash run_gochain.sh start
test-btp:
	bash post_install.sh sendBTPMessage
ibc-ready:
	bash run_gochain.sh start
	bash post_install.sh cfg
stop:
	bash run_gochain.sh stop