SUMMARY = "Class for downloading files from KP Labs' GitLab releases. \
It produces a GITLAB_ASSET_URL variable that can be used in recipes to download the asset."

GITLAB_ASSET_PROJECT_NUMBER ?= ""
GITLAB_ASSET_PROJECT_NUMBER[doc] = "Gitlab project number where the file is located"

GITLAB_ASSET_TAG ?= ""
GITLAB_ASSET_TAG[doc] = "Release tag of the project"

GITLAB_ASSET_NAME ?= ""
GITLAB_ASSET_NAME[doc] = "Name of the file to be downloaded from GitLab release"


python __anonymous() {
    import urllib.request
    import json

    expected = [
        "GITLAB_ASSET_PROJECT_NUMBER",
        "GITLAB_ASSET_NAME",
        "GITLAB_ASSET_TAG",
    ]

    for var in expected:
        if not d.getVar(var):
            bb.fatal(f"Missing required variable: {var}")

    gitlab_asset_project_number = d.getVar("GITLAB_ASSET_PROJECT_NUMBER")
    gitlab_asset_name = d.getVar("GITLAB_ASSET_NAME")
    gitlab_asset_tag = d.getVar("GITLAB_ASSET_TAG")

    assets_link = f"https://git.kplabs.pl/api/v4/projects/{gitlab_asset_project_number}/releases/{gitlab_asset_tag}/assets/links"
    direct_asset_url = ""

    with urllib.request.urlopen(assets_link) as url:
        links = json.load(url)
        for link in links:
            if "name" in link and "direct_asset_url" in link and link["name"] == gitlab_asset_name:
                direct_asset_url = link["direct_asset_url"]
                break

    if direct_asset_url == "":
        bb.error(f"Missing url for {gitlab_asset_name}")

    d.setVar("GITLAB_ASSET_URL", f'{direct_asset_url}')
}
