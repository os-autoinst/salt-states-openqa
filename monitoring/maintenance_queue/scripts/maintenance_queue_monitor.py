#!/usr/bin/env python3

import requests
import datetime
import json
import dateutil.parser
import socket
from types import SimpleNamespace


def gql_query(url, first=100, offset=0):
    query = f"""query {{
        requests(review_AssignedByGroup_Name_Iexact: "qam-sle", status_Name_Iexact:"review", first: 100, offset: {offset}) {{
        pageInfo {{
          hasNextPage
          hasPreviousPage
        }}
        edges {{
          node {{
            category {{
              name
            }}
            incident{{
          incidentId
        }}
            requestId
            endDate
            status{{
              name
            }}
            reviewSet {{
              edges {{
                node {{
                  assignedByGroup{{
                    name
                  }}
                  assignedByUser{{
                    username
                  }}
                  assignedTo{{
                    username
                  }}
                  status {{
                    name
                  }}
                  assignedAt
                  reviewedAt
                }}
              }}
            }}
          }}
        }}
      }}
    }}"""

    return requests.post(url, data={'query': query})


def gql_query_dec(url, first=100, offset=0):
    today = datetime.datetime.utcnow() - datetime.timedelta(days=1)
    today = today.isoformat()
    query = f"""query {{
        requests(review_AssignedByGroup_Name_Iexact: "qam-sle", status_Name_Iexact:"declined", endDate_Gt: "{today}", first: 100, offset: {offset}) {{
        pageInfo {{
          hasNextPage
          hasPreviousPage
        }}
        edges {{
          node {{
            requestId
        }}
      }}
    }}
}}"""

    return requests.post(url, data={'query': query})


def deserialize_json(json_string):
    """helper to convert a json string into proper python objects"""
    return json.loads(res.text, object_hook=lambda d: SimpleNamespace(**d))


url = "http://smelt.suse.de/graphql/"
first = 100

testing = set()
on_review = set()
sle_over = set()
tested = set()
incoming = set()
declined = set()
for i in range(0, 100):
    offset = i*100
    res = gql_query(url, first, offset)
    json_data = deserialize_json(res.text)
    for rr in json_data.data.requests.edges:
        rev_groups = {}
        rev_users = {}
        for rev in rr.node.reviewSet.edges:
            if rev.node.status.name == "new":
                if (rev.node.assignedByGroup is None or
                        rev.node.assignedByGroup.name != "maintenance-release-approver"):
                    testing.add(rr.node.requestId)
            if rev.node.assignedByGroup is not None:
                grp_name = rev.node.assignedByGroup.name
                rev_groups[grp_name] = {}
                rev_groups[grp_name]['assignedAt'] = rev.node.assignedAt
                if rev.node.assignedTo is not None:
                    rev_groups[grp_name]['user'] = rev.node.assignedTo.username
                else:
                    rev_groups[grp_name]['user'] = None

                rev_groups[grp_name]['status'] = rev.node.status.name
            elif rev.node.assignedByUser is not None:
                usr_name = rev.node.assignedByUser.username
                rev_users[usr_name] = {}
                rev_users[usr_name]['user'] = rev.node.assignedByUser.username
                rev_users[usr_name]['status'] = rev.node.status.name
                if rev.node.reviewedAt is not None:
                    rev_users[usr_name]['reviewedAt'] = rev.node.reviewedAt
        if (rr.node.requestId in testing and
                rev_groups['qam-sle']['user'] is not None and
                rev_groups['qam-sle']['status'] != "new"):
            on_review.add(rr.node.requestId)
            testing.remove(rr.node.requestId)
        if (rr.node.requestId in on_review and
                'reviewedAt' in rev_users[rev_groups['qam-sle']['user']]):
            on_review.remove(rr.node.requestId)
            sle_over.add(rr.node.requestId)
        if (rr.node.requestId not in testing and
                rr.node.requestId not in on_review and
                rr.node.requestId not in sle_over):
            tested.add(rr.node.requestId)
        as_at = dateutil.parser.isoparse(rev_groups['qam-sle']['assignedAt'])
        if (rr.node.requestId in testing and
                as_at.date() >= datetime.datetime.now().date()):
            incoming.add(rr.node.requestId)
    if json_data.data.requests.pageInfo.hasNextPage is False:
        break

for i in range(0, 100):
    offset = i*100
    res = gql_query_dec(url, first, offset)
    json_data = deserialize_json(res.text)
    for rr in json_data.data.requests.edges:
        declined.add(rr.node.requestId)
    if json_data.data.requests.pageInfo.hasNextPage is False:
        break

incoming = len(incoming)

queue = len(testing) + len(on_review)
queue_unassigned = len(testing)
queue_assigned = len(on_review)

outgoing = len(tested) + len(declined) + len(sle_over)
tested = len(tested)
declined = len(declined)
sle_finished = len(sle_over)
fqdn = socket.getfqdn()

res_string = "maintenance_queue,machine=%s " \
             "incoming=%di," \
             "queue=%di," \
             "outgoing=%di," \
             "queue_unassigned=%di," \
             "queue_assigned=%di," \
             "tested=%di," \
             "declined=%di," \
             "sle_finished=%di" % (fqdn,
                                   incoming,
                                   queue,
                                   outgoing,
                                   queue_unassigned,
                                   queue_assigned,
                                   tested,
                                   declined,
                                   sle_finished)

print(res_string)
