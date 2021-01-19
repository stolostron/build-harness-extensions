# Slack integration with not a lot of ceremony
#  Required environment variables:
#  SLACK_WEBHOOK_URL: fully formed URL including web hook, token, key
#  SLACK_MESSAGE: message to send

.PHONY: simple-slack/send
## Send a slack message
simple-slack/send: %send:
	$(call assert-set,SLACK_WEBHOOK_URL)
	$(call assert-set,SLACK_MESSAGE)
	curl -X POST -H 'Content-type: application/json' --data '{"text":"$(SLACK_MESSAGE)"}' $(SLACK_WEBHOOK_URL)
