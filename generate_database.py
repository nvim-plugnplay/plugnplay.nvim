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

            wanted_fields = ["full_name", "description", "default_branch", "fork", "archived", "private", "clone_url", "commits_url", "created_at", "updated_at", "stargazers_count", "subscribers_count", "forks_count", "language", "open_issues_count", "topics", "owner"]

            for field in plugin_data_json.keys():
                if field == "name":
                    plugin_name = plugin_data_json[field]
                if field in wanted_fields:
                    plugin_data[field] = plugin_data_json[field]

            if "commits_url" in plugin_data:
                commit_req = requests.get(plugin_data["commits_url"][:-6], auth=(client_id, client_secret))
                commit = commit_req.json()[-1]
                plugin_data["commit"] = commit["sha"]

            # Remove unneeded stuff from plugin data and merge plugin and commit data
            del plugin_data["commits_url"]
            plugin_data = { **plugin_data }
            plugins = { **plugins, f"{plugin_name}": { **plugin_data } }
            print("Parsed", plugin_data["full_name"])
        if not 'next' in req.links:
            break

    file.write(json.dumps(plugins, sort_keys=True, indent=4))

print("Success! Dumped", count - 1, "pages worth of plugins")
