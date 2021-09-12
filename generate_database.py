import re, requests, json

r = requests.get("https://raw.githubusercontent.com/rockerBOO/awesome-neovim/main/README.md")

print("Pulled awesome-neovim README")

count = 1

client_id = None
client_secret = None

with open("database.json", "+w") as file:
    print("Reading through line", count)
    for line in r.iter_lines():
        match = re.search(rb"-\s+\[([^/]+/[^]]+)\]\(([^)]+)\)\s+-\s+(.+)", line)
        if match:
            print("Match found for", match.group(1))
            req = requests.get(b"https://api.github.com/repos/" + match.group(1), auth=(client_id, client_secret))
            if req.text.find("API rate limit exceeded") != -1:
                print("We are being rate limited!")
                print(req.text)
                exit(-1)

            req_json = json.loads(req.text)
            # Extract only the data that we need
            plugin_data = {}
            wanted_fields = ["full_name", "description", "default_branch", "fork", "archived", "private", "clone_url", "commits_url", "created_at", "updated_at", "stargazers_count", "subscribers_count", "forks_count", "language", "open_issues_count"]
            for field in req_json.keys():
                if field == "name":
                    # Do magic that manipulates the JSON object here
                    pass
                if field in wanted_fields:
                    plugin_data[field] = req_json[field]

            # Get the latest commit relevant information
            if not "commits_url" in plugin_data:
                print("No commit URL found for", match.group(1), "- skipping...")
                continue

            req = requests.get(plugin_data["commits_url"], auth=(client_id, client_secret))
            if req.text.find("API rate limit exceeded") != -1:
                print("We are being rate limited!")
                print(req.text)
                exit(-1)

            req_json = json.loads(req.text)
            commit_data = {}
            wanted_fields = ["sha", "commit"]
            for field in req_json.keys():
                if field in wanted_fields:
                    if field == "commit":
                        commit_data["commit_date"] = req_json["commit"]["author"]["date"]
                    else:
                        commit_data[field] = req_json[field]

            # Remove not needed stuff from plugin data and merge plugin and commit data
            del plugin_data["commits_url"]
            plugin_data = {**plugin_data, **commit_data}

            file.write(json.dumps(plugin_data, sort_keys=True, indent=4))
            count += 1
            print("---- DUMPED JSON ----")
    file.close()

print("Success! Dumped", count, "repos!")
