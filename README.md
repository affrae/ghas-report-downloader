# GitHub Code Scanning Report Downloader

Goal is to list reports and allow the user to select the report they want to download. Also to teach myself some Ruby.

Reports will be downloaded in `.sarif` format and can be viewed in a IDE's SARIF viewer plugin

GitHub.com / GitHub Enterprise Cloud support only at this point in time

Code scanning is available for all public repositories and for private repositories owned by organizations where GitHub Advanced Security is enabled. For more information, see "[About GitHub Advanced Security](https://docs.github.com/en/github/getting-started-with-github/about-github-advanced-security)."

## Requirements

To run this script, please set the following environment variables:

- `GITHUB_PAT`: A Personal Access Token (PAT) for your account (eg `export GITHUB_PAT=ghp_abc123`)

## To run

``` zsh
bundle install
./ghasrd.rb
```

### Listing available reports

``` zsh
➜  ghas-report-downloader git:(main) ./ghasrd.rb -l -o affrae -r quickjavahelloworldmultimodule
Listing available reports for https://github.com/affrae/quickjavahelloworldmultimodule...
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| ID      | Tool   | Commit SHA(7) | Commit date             | Commit author   | Commit message                          |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6568185 | CodeQL | 1161a60       | 2021-04-22 06:53:26 UTC | Daniel Figucio  | Update README.md                        |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6516422 | CodeQL | 1161a60       | 2021-04-20 23:30:07 UTC | Daniel Figucio  | Update README.md                        |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6516391 | CodeQL | 7e79a09       | 2021-04-20 23:29:00 UTC | dependabot[bot] | Bump junit from 4.11 to 4.13.1 in /w... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6516390 | CodeQL | 4cf7679       | 2021-04-20 23:28:58 UTC | Daniel Figucio  | Merge pull request #1 from affrae/de... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6516388 | CodeQL | c920fc2       | 2021-04-20 23:28:54 UTC | dependabot[bot] | Bump junit from 4.11 to 4.13.1 in /w... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6516361 | CodeQL | 6b178dd       | 2021-04-20 23:27:52 UTC | Daniel Figucio  | Merge pull request #4 from affrae/de... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6326184 | CodeQL | 7b1eccd       | 2021-04-15 06:53:06 UTC | Daniel Figucio  | Update App.java                         |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 6089337 | CodeQL | 7b1eccd       | 2021-04-08 06:53:45 UTC | Daniel Figucio  | Update App.java                         |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5881321 | CodeQL | 18af178       | 2021-04-01 08:21:19 UTC | dependabot[bot] | Merge eaf1ca73915a559e783378d39eecc5... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5881308 | CodeQL | fb104c5       | 2021-04-01 08:21:04 UTC | dependabot[bot] | Merge ac1fac1fcb823b254cd51b36821379... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5881292 | CodeQL | 0cebba7       | 2021-04-01 08:20:46 UTC | dependabot[bot] | Merge 1479c0dee564a5ec9dbc8d82b225da... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5881218 | CodeQL | ebca64e       | 2021-04-01 08:18:32 UTC | dependabot[bot] | Merge fb39ac581dfefccd29e9233316b925... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5879878 | CodeQL | 7b1eccd       | 2021-04-01 07:37:14 UTC | Daniel Figucio  | Update App.java                         |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5877531 | CodeQL | 7b1eccd       | 2021-04-01 06:07:20 UTC | Daniel Figucio  | Update App.java                         |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5877245 | CodeQL | 641ee8e       | 2021-04-01 05:56:05 UTC | Daniel Figucio  | Update App.java                         |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5877019 | CodeQL | 7cbfb83       | 2021-04-01 05:49:25 UTC | Daniel Figucio  | Update codeql-analysis.yml              |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5876864 | CodeQL | adc456e       | 2021-04-01 05:44:12 UTC | Daniel Figucio  | added custom config to codeql analys... |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5876671 | CodeQL | 9128b15       | 2021-04-01 05:38:41 UTC | Daniel Figucio  | added a custom query                    |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+
| 5876116 | CodeQL | 1f14ad5       | 2021-04-01 05:21:38 UTC | Daniel Figucio  | Create codeql-analysis.yml              |
+---------+--------+---------------+-------------------------+-----------------+-----------------------------------------+

To get a report issue the command
  ./ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g [ID]
where [ID] is the ID of the analysis you are interested in from the table above.                                                                                                                                                                                                                                                               /6.1s
➜  ghas-report-downloader git:(main) 
```

## Downloading reports

If you know the ID (or multiple IDs) for an analyis (you can get a list of IDs using the `-l` option), you can use the following command to download the currrent code scanning report for that PR:

``` shell
# single
ghasrd.rb -o [OWNER] -r [REPO] -g 5876671

# multiple
ghasrd.rb -o [OWNER] -r [REPO] -g 5876671,5876116

```

### Download the current report for a PR

If you know the number of a PR (or multiple PRs), you can use the following command to download the currrent code scanning report for that PR:

``` shell
# single
ghasrd.rb -o [OWNER] -r [REPO] -p 2045

# multiple
ghasrd.rb -o [OWNER] -r [REPO] -p 1257,2045
```

## To Be Done

### Short term

- [x] Error Checking and Handling
- [x] User Input Data checking and sanitization
- [x] Better details in the list reports function to help choose which report
- [x] Download the report(s) using the `-g` option (listing report analysis IDs)
- [x] Download the report for the most recent commit to a Pull Request source branch using the `-p` option (listing Pull Request numbers )
- [ ] Better docs

### Mid term

- [ ] Verbose `-v` and `-V` levels sorted out (right now it is a little noisy)
- [ ] Support for GitHub Enterprise Server
- [ ] Support for GitHub Æ

### Long term

- [ ] Interactivity to filter, choose and download multiple reports within one execution of the tool
