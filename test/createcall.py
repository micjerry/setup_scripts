# -*- coding: utf-8 -*- 
import urllib.parse
import http.client
import json
import sys
import uuid


class TestCase:
    def __init__(self):
        pass

    def test(self):
        taskid = str(uuid.uuid4())
        input = {
            "taskid" : taskid,
			"groupid" : "alis23",
            "userid" : "ak989",
            "robotid": "abs",
            "callernumber" : "158765",
            "calleenumbers" : ["15986657987"],
            "gateway" : "",
            "swid" : "localoneshot",
            "maxduration" : 240,
            "ringduration" : 30,
            "dialog" : {
			  "id": "sw189",
              "name": "getwill",
              "nodes" : [
                {
                  "name": "hello",
                  "play":"ivr/ivr-welcome_to_freeswitch.wav",
                  "fileId": "10",
                  "duration" : 5,
                  "canbreak" : False,
                  "hangup" : False,
                  "first" : True,
                  "retryTimes" : 0,
                  "sysType" : "",
                  "branchs" : [ 
                    {
                      "match" : "可以-好的-喂",
                      "node" : "intro"
                    }
                  ]
                },
                {
                  "name": "intro",
                  "play":"ivr/ivr-this_ivr_will_let_you_test_features.wav",
                  "fileId": "12",
                  "duration" : 5,
                  "canbreak" : False,
                  "hangup" : True,
                  "first" : False,
                  "retryTimes" : 0,
                  "sysType" : ""
                }
              ],
              "syses" : [
                {
                  "name": "bye",
                  "play":"ivr/ivr-this_ivr_will_let_you_test_features.wav",
                  "fileId": "13",
                  "duration" : 8,
                  "canbreak" : False,
                  "hangup" : True,
                  "first" : False,
                  "retryTimes" : 0,
                  "sysType" : "bye"
                }
              ]
              
            }
        }

        params = json.dumps(input)

        headers = {
            "Host": "192.168.5.23",
            "Content-Type": "application/json;charset=utf-8"
        }

        try:
            connection = http.client.HTTPConnection("192.168.5.23", 80)
            connection.request("POST", "/swcall/createcall", params, headers)
            response = connection.getresponse().read()
            print("response = (%s)" % response)
            connection.close()
        except Exception as e:
            print("error = (%s)" % str(e))

if __name__ == "__main__":
    ts = TestCase()
    ts.test()

