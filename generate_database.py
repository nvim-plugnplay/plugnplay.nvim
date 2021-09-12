import re, requests, json

r = requests.get("https://raw.githubusercontent.com/rockerBOO/awesome-neovim/main/README.md")

print("Pulled awesome-neovim README")

count = 0

with open("database.json", "+w") as file:
    print("Reading through line", count)
    for line in r.iter_lines():
        match = re.search(rb"-\s+\[([^/]+/[^]]+)\]\(([^)]+)\)\s+-\s+(.+)", line)
        if match:
            print("Match found for", match.group(1))
            req = requests.get(b"https://api.github.com/repos/" + match.group(1))
            file.write(json.dumps(req.text, sort_keys=True, indent=4))
            count += 1
            print("---- DUMPED JSON ----")
    file.close()

print("Success! Dumped", count, "repos!")
