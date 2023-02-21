# version-bump-action

This action is designed to bump/release a gradle or maven build repository which has a version declared in a
semantic version format `x.y.z`.
It will bump the version of the repo pushing the change into the current branch that was checked out,
and create a new git tag for the release.
A Github Actions summary will be produced to inform about what happened.

## How to Use

It should be used as follows
```yaml
steps:
  - uses: actions/checkout@v3.1.0

  - name: Set up JDK 17
    uses: actions/setup-java@v3.6.0
    with:
      java-version: '17'
      distribution: 'temurin'
      cache: 'gradle'
  
  - name: Bump Version
    id: bump
    uses: IMGARENA/version-bump-action@<latest_version>
    with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Available Build Styles

The action will handle the following styles of builds

#### Maven

The version property will be updated inside the pom.xml

#### Gradle

Three variations exist inside Gradle builds where the version can be declared:

* Groovy Gradle file `build.gradle`
* Kotlin Gradle file `build.gradle.kts`
* Gradle Properties file `gradle.properties`

For the "build" files the action will handle/expect the version to be declared in the usual format, 
handling with/without spaces and using `"` or `'` to wrap the declared version

For the "properties" file the version would be declared in the normal properties file format.

## Controlling Semantic Release

The release "type" will default to a "patch" release which will bump the version to `x.y.(z+1)`.
To perform a minor or major release the last commit message needs to contain `#minor` or `#major` (respectively) somewhere
in the message.
It does not have to be in the commit title.

## Inputs

The action will accept the following inputs:

| Parameter                | Required | Description                                                   | Default                                        |
|--------------------------|----------|---------------------------------------------------------------|------------------------------------------------|
| `github-token`           | Yes      | A GitHub auth token to be able to create the pull request     |                                                |
| `version-filepath`       | No       | The relative location of your "build" file                    | `.` |
| `sub-project`            | No       | If multi-project specify the project to bump                     | `:my-super-project` |
| `git-author-email`       | No       | The email address to be used as the author for the release    | `${{ github.actor }}@users.noreply.github.com` |
| `git-author-username`    | No       | The name to be used as the author for the release             | `${{ github.actor }}`                          |  
| `git-committer-email`    | No       | The email address to be used as the committer for the release | `bumpVersionBot@users.noreply.github.com`      |
| `git-committer-username` | No       | The name to be used as the committer for the release          | `github-actions[bot]`                          |

## Outputs

The following 2 outputs are available from the actions

| Parameter         | Description                                | 
|-------------------|--------------------------------------------|
| `version`         | The final version (whether updated or not) |
| `initial-version` | The initial version before the action ran  |



## Gotchas

### Protected Branches

If you are trying to push to a protected branch then the `${{ secrets.GITHUB_TOKEN }}` will not be enough to bypass
the protections. 
You will need a Personal Access Token, or an Organisation Bot token, with admin privileges to be passed in via the 
`github-token` input.

