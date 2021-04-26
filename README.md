# GitHub Code Scanning Report Downloader

`ghasrd.rb` lists code scanning SARIF reports for a given GitHub hosted repository and allows the user to identify and download these reports.

Reports will be downloaded in a standard `.sarif` format and can be viewed in a IDE's SARIF viewer plugin.

GitHub.com / GitHub Enterprise Cloud support only at this point in time.

Code scanning is available for all public repositories and for private repositories owned by organizations where GitHub Advanced Security is enabled. For more information, see "[About GitHub Advanced Security](https://docs.github.com/en/github/getting-started-with-github/about-github-advanced-security)."

## Requirements

To run this script, please set the following environment variables:

- `GITHUB_PAT`: A Personal Access Token (PAT) for your account (eg `export GITHUB_PAT=ghp_abc123`)

## To run

- Download and unpack the latest version from the [releases page](https://github.com/affrae/ghas-report-downloader/releases).
- Hop into the unpacked directory and issue the following:

``` zsh
bundle install
```

- Place the `ghasrd.rb` script in your $PATH, make sure it is executable.
- Hop into the root directory of your repository and issue the `ghasrd.rb` command with appropriate options (detailed below).

### Filenames and `.gitignore`

The downloaded files are of the filename formats:

- `analysis_[ID].sarif`
- `pr_[PR#]_analysis_[ID].sarif`
- `sha_[SHA]_analysis_[ID].sarif`

you can add an appropriate pattern to your `.gitignore` file to stop them being pushed to the GitHub repository.

### Listing available reports

``` zsh
ghasrd.rb -o [OWNER] -r [REPO] -l
```

#### Sample output

``` zsh
➜  ghas-report-downloader git:(main) ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -l        
Getting a list of available reports for https://github.com/affrae/quickjavahelloworldmultimodule...done.
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

To get an report issue the command:
  ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g [ID]
where [ID] is the ID of the analysis report you are interested in from the table above.
For example:
  ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g  5876116 
to get the last report on that table                                                                                                                 /6.2s
➜  ghas-report-downloader git:(main) 
```

### Downloading reports
#### By analysis ID

If you know the ID (or multiple IDs) for an analyis (you can get a list of IDs using the `-l` option), you can use the following command to download the report for each ID:

``` shell
# single
ghasrd.rb -o [OWNER] -r [REPO] -g 5876671

# multiple
ghasrd.rb -o [OWNER] -r [REPO] -g 5876671,5876116

```

Files are stored in the format `analysis_[ID].sarif`

#### By Pull Request Number (PR)

If you know the number of a PR (or multiple PRs), you can use the following command to download the code scanning reports for the HEAD sha of each PR:

``` shell
# single
ghasrd.rb -o [OWNER] -r [REPO] -p 2045

# multiple
ghasrd.rb -o [OWNER] -r [REPO] -p 1257,2045
```

Files are stored in the format `pr_[PR#]_analysis_[ID].sarif`

#### By commit SHA

If you know the SHA of a commit (SHAs of multiple commits), you can use the following command to download the code scanning reports for each SHA:

``` shell
# single
ghasrd.rb -o [OWNER] -r [REPO] -s 9128b15

# multiple
ghasrd.rb -o [OWNER] -r [REPO] -s 9128b15,7b1eccd
```

We can figure out what commit you’re referring to _if you provide as few as the the first four characters of the `SHA-1` hash_, as long as that partial hash is  unambiguous - that is, no other commit can have a hash that begins with the same prefix. This means you do not need to enter all 40 characters of every SHA-1 hash you are after :smiling_imp:&nbsp;.

Files are stored in the format `sha_[SHA]_analysis_[ID].sarif`

## To Be Done

### Short term

- [x] Error Checking and Handling
- [x] User Input Data checking and sanitization
- [x] Better details in the list reports function to help choose which report
- [x] Download the report(s) using the `-g` option (listing report analysis IDs)
- [x] Download the report(s) for the most recent commit to a Pull Request source branch using the `-p` option (listing Pull Request numbers )
- [x] Download the report(s) for a given Commit SHA or list of Commit SHAs
- [ ] Enable an option to provide a directory to download the reports to
- [ ] Better docs

### Mid term

- [ ] Verbose `-v` and `-V` levels sorted out (right now it is a little noisy)
- [ ] Implement a unit testing framework
- [ ] Support for GitHub Enterprise Server
- [ ] Support for GitHub Æ

### Long term

- [ ] Interactivity to filter, choose and download multiple reports within one execution of the tool
