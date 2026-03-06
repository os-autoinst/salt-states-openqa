#!/usr/bin/env python3

import requests
import datetime
import json
import dateutil.parser
import socket
import time
import re
from collections import Counter
from types import SimpleNamespace
from datetime import datetime, timedelta, timezone


GITEA_TOKEN = "{{ pillar.get('credentials', {}).get('gitea', {}).get('gitea_api_key', '') }}"

# Tell jinja not to evaluate the rest of the code
{% raw %} 

ASSIGNMENT_PATTERN = re.compile(r"<MTUI: PR - UV assigned to user: .*? - group: qam-sle >")


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
    today = datetime.utcnow() - timedelta(days=1)
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
    return json.loads(json_string, object_hook=lambda d: SimpleNamespace(**d))

def smelt1_updates():
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
                  rev_groups['qam-sle']['user'] in rev_users and
                  'reviewedAt' in rev_users[rev_groups['qam-sle']['user']]):
              on_review.remove(rr.node.requestId)
              sle_over.add(rr.node.requestId)
          if (rr.node.requestId not in testing and
                  rr.node.requestId not in on_review and
                  rr.node.requestId not in sle_over):
              tested.add(rr.node.requestId)
          as_at = dateutil.parser.isoparse(rev_groups['qam-sle']['assignedAt'])
          if (rr.node.requestId in testing and
                  as_at.date() >= datetime.now().date()):
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

  return {
    "INCOMING": incoming,
    "OUTGOING": outgoing,
    "QUEUE SIZE": queue,
    "UNASSIGNED_UPDATES": queue_unassigned,
    "ASSIGNED_UPDATES": queue_assigned, 
    "DECLINED": declined,
    "TESTED": tested,
    "SLE_FINISHED": sle_finished
  }

def search_closed_prs(gitea_url, repo_owner, repo_name, token, days=5, search_strings=None):
    """
    Searches closed (not merged) PRs in a Gitea repo that were closed in the past X days.
    Checks all comments on those PRs for specific strings.
    """
    if search_strings is None:
        search_strings = ["@qam-openqa-review: decline", "@qam-sle-review: decline"]
        
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/json"
    }
    
    # Calculate the cutoff date
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=days)
    base_api_url = f"{gitea_url.rstrip('/')}/api/v1/repos/{repo_owner}/{repo_name}"
    
    results = []
    page = 1
    keep_fetching = True
    
    while keep_fetching:
        prs_url = f"{base_api_url}/pulls"
        params = {
            "state": "closed",
            "sort": "recentupdate", # Keeps the newest updates at the top of page 1
            "page": page,
            "limit": 50
        }
        
        response = requests.get(prs_url, headers=headers, params=params)
        response.raise_for_status()
        prs = response.json()
        
        if not prs:
            break 
            
        for pr in prs:
            # check updated_at to know when to stop fetching pages
            updated_at_str = pr.get("updated_at")
            if updated_at_str:
                pr_updated = dateutil.parser.isoparse(updated_at_str)
                if pr_updated < cutoff_date:
                    # If it wasn't even updated in our window, it couldn't have been closed in our window
                    keep_fetching = False
                    break

            # only process if it was CLOSED within our time window
            closed_at_str = pr.get("closed_at")
            if not closed_at_str:
                continue # Edge case fallback
                
            pr_closed = dateutil.parser.isoparse(closed_at_str)
            if pr_closed < cutoff_date:
                continue # It was closed before our 5-day window, skip processing
                
            # skip if the PR was successfully merged
            if pr.get("merged_at") is not None:
                continue
                
            # if we reach here, it's a non-merged PR closed in the last 5 days
            
            pr_index = pr["number"]
            comments_url = f"{base_api_url}/issues/{pr_index}/comments"
            
            comments_response = requests.get(comments_url, headers=headers)
            comments_response.raise_for_status()
            comments = comments_response.json()
            
            matching_comments = []
            
            # Define the prefixes we want to ignore
            ignore_prefixes = (
                "Review by qam-sle-review represents", 
                "Review by qam-openqa-review represents"
            )
            
            # Scan ALL comments (regardless of date) for the target strings
            for comment in comments:
                body = comment.get("body", "")
                
                # Skip the comment entirely if it starts with an ignored prefix
                if body.strip().startswith(ignore_prefixes):
                    continue
                    
                for search_str in search_strings:
                    if search_str in body:
                        matching_comments.append({
                            "comment_id": comment["id"],
                            "user": comment["user"]["login"],
                            "body": body,
                            "created_at": comment["created_at"],
                            "url": comment.get("html_url", "")
                        })
                        break
                        
            if matching_comments:
                results.append({
                    "pr_number": pr_index,
                    "pr_title": pr["title"],
                    "pr_url": pr.get("html_url", ""),
                    "closed_at": closed_at_str,
                    "matching_comments": matching_comments
                })
                
        page += 1

    return results

def get_declined_prs(
    gitea_url="https://src.suse.de/", 
    repo_owner="products", 
    repo_name="SLFO", 
    token=GITEA_TOKEN, 
    days=5, 
    print_results=False
):
    found_data = search_closed_prs(
        gitea_url=gitea_url,
        repo_owner=repo_owner,
        repo_name=repo_name,
        token=token,
        days=days
    )
    
    declined = set()
    for item in found_data:
        if print_results:
            print(f"PR #{item['pr_number']}: {item['pr_title']} (Closed: {item['closed_at']})")
            print(f"Link: {item['pr_url']}")
            for comment in item['matching_comments']:
                print(f"  -> Match by {comment['user']} at {comment['created_at']}")
            print("-" * 40)
            
        declined.add(item['pr_number'])
        
    return declined

def check_pr_assignment(pr_url, token=GITEA_TOKEN):
    """
    Parses a full Gitea PR URL, fetches its comments, and checks for a specific 
    MTUI assignment string. Returns 1 if found, 0 otherwise.
    """
    # 1. Parse the PR URL to construct the API URL directly
    parts = pr_url.rstrip('/').split('/')
    try:
        pr_index = parts[-1]
        repo_name = parts[-3]
        repo_owner = parts[-4]
        base_url = '/'.join(parts[:-4])
    except IndexError:
        print(f"Error: Could not parse PR URL: {pr_url}")
        return 0
        
    api_url = f"{base_url}/api/v1/repos/{repo_owner}/{repo_name}/issues/{pr_index}/comments"
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/json"
    }
    
    # 2. Fetch the comments
    try:
        response = requests.get(api_url, headers=headers, timeout=10)
        response.raise_for_status()
        comments = response.json()
    except requests.RequestException as e:
        print(f"API Error fetching comments for PR #{pr_index}: {e}")
        return 0
        
    # 3. Scan comments and return 1 immediately upon the first match
    for comment in comments:
        body = comment.get("body", "")
        if ASSIGNMENT_PATTERN.search(body):
            return 1 # early exit makes this as fast as possible
            
    return 0

def process_updates(api_url):
    try:
        response = requests.get(api_url)
        response.raise_for_status()
        json_payload = response.json()
        
        items = json_payload.get("data", [])
        
        # print(f"Total number of items: {len(items)}")
        
        # number of items per distinct "status"
        status_counts = Counter(item.get("status", "Unknown") for item in items)
        
        testing_set = get_testing_ids(items)   
        sle_over_set = get_sle_over_ids(items, testing_set)
        incoming_set = get_incoming_ids(items)
        tested_set = get_tested_ids(items)

        two_days_ago = datetime.now(timezone.utc) - timedelta(days=2)
        merged_set = get_merged_ids(items, after_date=two_days_ago)
        assigned_unassigned_set = get_assigned_count(items, testing_set)
        declined_prs = get_declined_prs()
        


        return {
            "INCOMING": len(incoming_set),
            "OUTGOING": len(tested_set) + len(sle_over_set) + len(merged_set),
            "QUEUE SIZE": len(testing_set),
            "UNASSIGNED_UPDATES": assigned_unassigned_set["UNASSIGNED"],
            "ASSIGNED_UPDATES": assigned_unassigned_set["ASSIGNED"], 
            # "SLE_OVER": len(sle_over_set),
            # "TESTED_RECENT": len(merged_set),
            "DECLINED": len(declined_prs),
            "TESTED": len(tested_set),
            "SLE_FINISHED": len(sle_over_set)
        }
      
    except requests.exceptions.RequestException as e:
        print(f"Failed to fetch data from the API. Error: {e}")

def get_testing_ids(items):
    """
    Returns a set of IDs for updates that are in 'testing' status 
    and have 'qam-sle-review' in their testers list.
    """
    testing_ids = set()
    for item in items:
        if item.get("status") == "testing":
            # check if 'qam-sle-review' is one of the testers
            testers = item.get("testers", [])
            for tester in testers:
                if tester.get("groupname") == "qam-sle-review":
                    testing_ids.add(item.get("id"))
                    break  # found the target group, move to the next item
                    
    return testing_ids


def get_sle_over_ids(items, testing_ids):
    """
    Returns a set of IDs for updates that are currently in the 'testing_ids' set 
    AND have an APPROVED review from 'qam-sle-review'.
    """
    sle_over_ids = set()
    for item in items:
        item_id = item.get("id")
        
        # Only check items that we already know are in the 'testing' bucket
        if item_id in testing_ids:
            reviews = item.get("reviews", [])
            for review in reviews:
                if review.get("state") == "APPROVED" and review.get("name") == "qam-sle-review":
                    sle_over_ids.add(item_id)
                    break  # found the approval, move to the next item
                    
    return sle_over_ids

def get_incoming_ids(items):
    """
    Returns a set of IDs for updates that are in 'patchinfo_missing' status 
    AND have a 'REQUEST_REVIEW' state from 'qam-sle-review'.
    """
    incoming_ids = set()
    for item in items:
        if item.get("status") == "patchinfo_missing" or item.get("status") == "patchinfo_created":
            reviews = item.get("reviews", [])
            for review in reviews:
                if review.get("name") == "qam-sle-review":
                    incoming_ids.add(item.get("id"))
                    break  # met the condition, move to the next item
                    
    return incoming_ids

def get_tested_ids(items):
    """
    Returns a set of IDs for updates that are in 'tested' status 
    AND have an entry in 'reviews' with 'name': 'qam-sle-review'.
    """
    tested_ids = set()
    for item in items:
        if item.get("status") == "tested":
            reviews = item.get("reviews", [])
            for review in reviews:
                if review.get("name") == "qam-sle-review":
                    tested_ids.add(item.get("id"))
                    break  # met the condition, move to the next item
                    
    return tested_ids

def get_merged_ids(items, after_date=None):
    """
    Returns a set of IDs for updates in 'accepted_merged' status with a 
    'qam-sle-review' review. If after_date is provided, it also requires 
    a 'testing' timeline entry finished strictly after that date.
    """
    merged_ids = set()
    for item in items:
        if item.get("status") == "accepted_merged":
            
            # Check for the 'qam-sle-review' review
            has_qam_review = False
            reviews = item.get("reviews", [])
            for review in reviews:
                if review.get("name") == "qam-sle-review":
                    has_qam_review = True
                    break
            
            if not has_qam_review:
                continue

            # If after_date is provided, check the 'testing' timeline
            if after_date is not None:
                date_condition_met = False
                timeline = item.get("timeline", [])
                
                for step in timeline:
                    if step.get("name") == "testing":
                        finished_at_str = step.get("finished_at")
                        if finished_at_str:
                            finished_at_str = finished_at_str.replace('Z', '+00:00')
                            try:
                                finished_at = datetime.fromisoformat(finished_at_str)
                                if finished_at > after_date:
                                    date_condition_met = True
                                    break
                            except ValueError:
                                pass
                
                if not date_condition_met:
                    continue

            merged_ids.add(item.get("id"))
                    
    return merged_ids

def get_assigned_count(items, testing_ids):
    """
    Returns the total count of assigned PRs by checking the external URL 
    of items that have a 'REQUEST_REVIEW' state from 'qam-sle-review'.
    """
    assigned_count = 0
    total_review_count = 0
    for item in items:
        item_id = item.get("id")
        
        # Only check items that we already know are in the 'testing' bucket
        if item_id in testing_ids:
            reviews = item.get("reviews", [])
            for review in reviews:
                if review.get("name") == "qam-sle-review" and review.get("state") == "REQUEST_REVIEW":
                    total_review_count += 1
                    external_url = item.get("external_url")
                    
                    if external_url:
                        try:
                            result = check_pr_assignment(external_url)
                            if isinstance(result, int):
                                assigned_count += result
                        except Exception:
                            pass
                    
                    # We found the relevant review and processed the URL, move to the next item
                    break 
                
    return {
        "ASSIGNED": assigned_count,
        "UNASSIGNED": total_review_count - assigned_count
    }
slfo_updates = process_updates("https://smelt.suse.de/api/experimental/v2/updates/unreleased")
non_slfo_updates = smelt1_updates()
all_updates = {k: slfo_updates[k] + non_slfo_updates[k] for k in slfo_updates}

res_string = (
    "maintenance_queue,machine=%s "
    "incoming=%di,"
    "queue=%di,"
    "outgoing=%di,"
    "queue_unassigned=%di,"
    "queue_assigned=%di,"
    "tested=%di,"
    "declined=%di,"
    "sle_finished=%di"
    % (
        socket.getfqdn(),
        all_updates["INCOMING"],
        all_updates["QUEUE SIZE"],
        all_updates["OUTGOING"],
        all_updates["UNASSIGNED_UPDATES"],
        all_updates["ASSIGNED_UPDATES"],
        all_updates["TESTED"],
        all_updates["DECLINED"],
        all_updates["SLE_FINISHED"]

    )
)

print(res_string)
{% endraw %}
