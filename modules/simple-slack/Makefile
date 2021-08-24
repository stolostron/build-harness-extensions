# Slack integration with not a lot of ceremony
#
#  Required environment variables:
#  SLACK_WEBHOOK_URL: fully formed URL including web hook, token, key
#  SLACK_MESSAGE: message to send
#
#  Required environment variables for replying to a thread - assembled from a URL link:
#  SLACK_CHANNEL
#  SLACK_PARENT_MESSAGE_TS

.PHONY: simple-slack/send
## Send a slack message
simple-slack/send: %send:
	$(call assert-set,SLACK_WEBHOOK_URL)
	$(call assert-set,SLACK_MESSAGE)
	curl -X POST -H 'Content-type: application/json' --data '{"text":"$(SLACK_MESSAGE)"}' $(SLACK_WEBHOOK_URL)

.PHONY: simple-slack/thread
## Send a slack message as a threaded response
simple-slack/thread: %thread:
	$(call assert-set,SLACK_WEBHOOK_URL)
	$(call assert-set,SLACK_MESSAGE)
	$(call assert-set,SLACK_CHANNEL)
	$(call assert-set,SLACK_PARENT_MESSAGE_TS)
	curl -X POST -H 'Content-type: application/json' --data '{"text":"$(SLACK_MESSAGE)","channel":"$(SLACK_CHANNEL)","thread_ts":"$(SLACK_PARENT_MESSAGE_TS)"}' $(SLACK_WEBHOOK_URL)
