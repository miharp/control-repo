# @summary A demo agent: something visible to apply, nothing else.
#
# The screenshare edits the message, deploys with codavox, and shows the new
# notice arriving with a catalog stamped with the new code_id.
class role::demo_agent {
  notify { 'after a failed cache flush': }
}
