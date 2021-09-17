import os
import requests, json

# TODO: Look through plugin categories and check whether they have "Neovim" in them
# or just implement some sort of smarter filtering in general

client_id = os.getenv("CLIENT_ID")
client_secret = os.getenv("CLIENT_SECRET")

with open("database.json", "+w") as file:
    plugins = {}
    count = 1

    while True:
        req = requests.get("https://api.github.com/users/budswa/starred?per-page=1&page=" + str(count), auth=(client_id, client_secret))
        print("Grabbed page", count)
        count += 1
        if req.text.find("API rate limit exceeded") != -1:
            print("We are being rate limited!")
            print(req.text)
            exit(-1)
        for plugin_data_json in req.json():
            if not plugin_data_json["language"] or plugin_data_json["language"] != "Lua":
                continue

            # Extract only the data that we need
            plugin_data = {}
            plugin_name = ""

            wanted_fields = ["full_name", "description", "default_branch", "fork", "archived", "private", "clone_url", "commits_url", "created_at", "updated_at", "stargazers_count", "subscribers_count", "forks_count", "language", "open_issues_count"]
            for field in plugin_data_json.keys():
                if field == "name":
                    plugin_name = plugin_data_json[field]
                if field in wanted_fields:
                    plugin_data[field] = plugin_data_json[field]

            # Remove unneeded stuff from plugin data and merge plugin and commit data
            del plugin_data["commits_url"]
            plugin_data = { **plugin_data }
            plugins = { **plugins, f"{plugin_name}": { **plugin_data } }
            print("Parsed", plugin_data["full_name"])
        if not 'next' in req.links:
            break

    file.write(json.dumps(plugins, sort_keys=True, indent=4))

print("Success! Dumped", count, "pages worth of plugins")


# with open("database.json", "+w") as file:
#     # Save all plugins stuff in a dictionary
#     plugins = {}

#     print("Reading through line", count)
#     for line in r.iter_lines():
#         match = re.search(rb"-\s+\[([^/]+/[^]]+)\]\(([^)]+)\)\s+-\s+(.+)", line)
#         if match:
#             print("Match found for", match.group(1))
#             req = requests.get(b"https://api.github.com/repos/" + match.group(1), auth=(client_id, client_secret))
#             if req.text.find("API rate limit exceeded") != -1:
#                 print("We are being rate limited!")
#                 print(req.text)
#                 exit(-1)

#             req_json = json.loads(req.text)
#             # Extract only the data that we need
#             plugin_data = {}
#             plugin_name = ""
#             wanted_fields = ["full_name", "description", "default_branch", "fork", "archived", "private", "clone_url", "commits_url", "created_at", "updated_at", "stargazers_count", "subscribers_count", "forks_count", "language", "open_issues_count"]
#             for field in req_json.keys():
#                 if field == "name":
#                     plugin_name = req_json[field]
#                 if field in wanted_fields:
#                     plugin_data[field] = req_json[field]

#             # Get the latest commit relevant information
#             if not "commits_url" in plugin_data:
#                 print("No commit URL found for", match.group(1), "- skipping...")
#                 continue

#             req = requests.get(plugin_data["commits_url"], auth=(client_id, client_secret))
#             if req.text.find("API rate limit exceeded") != -1:
#                 print("We are being rate limited!")
#                 print(req.text)
#                 exit(-1)

#             req_json = json.loads(req.text)
#             commit_data = {}
#             wanted_fields = ["sha", "commit"]
#             for field in req_json.keys():
#                 if field in wanted_fields:
#                     if field == "commit":
#                         commit_data["commit_date"] = req_json["commit"]["author"]["date"]
#                     else:
#                         commit_data[field] = req_json[field]

#             # Remove not needed stuff from plugin data and merge plugin and commit data
#             del plugin_data["commits_url"]
#             plugin_data = {**plugin_data, **commit_data}
#             plugins = {**plugins, f"{plugin_name}": {**plugin_data}}
#             print("---- DUMPED JSON ----")
#             count += 1

#     file.write(json.dumps(plugins, sort_keys=True, indent=4))
#     file.close()

# print("Success! Dumped", count, "repos!")
