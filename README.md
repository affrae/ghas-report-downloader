# GitHub Code Scanning Report Downloader

Goal is to list reports and allow the user to select the report they want to download. Also to teach myself some Ruby.


Reports will be downloaded in `.sarif` format and can be viewed in a IDE's SARIF viewer plugin

GitHub.com / GitHub Enterprise Cloud support only at this point in time

Code scanning is available for all public repositories and for private repositories owned by organizations where GitHub Advanced Security is enabled. For more information, see "[About GitHub Advanced Security](https://docs.github.com/en/github/getting-started-with-github/about-github-advanced-security)."
## Requirements

To run this script, please set the following environment variables:

- `GITHUB_PAT`: A Personal Access Token (PAT) for your account

## To run:

``` zsh
bundle install
./ghasrd.rb
```
### Listing available reports

``` zsh
➜  ghas-report-downloader git:(main) ✗ ./ghasrd.rb -l -o affrae -r quickjavahelloworldmultimodule
Listing available reports for affrae/quickjavahelloworldmultimodule
+---------+------------+
| ID      | Commit SHA |
+---------+------------+
| 6516422 | 1161a60    |
| 6516391 | 7e79a09    |
| 6516390 | 4cf7679    |
| 6516388 | c920fc2    |
| 6516361 | 6b178dd    |
| 6326184 | 7b1eccd    |
| 6089337 | 7b1eccd    |
| 5881321 | 18af178    |
| 5881308 | fb104c5    |
| 5881292 | 0cebba7    |
| 5881218 | ebca64e    |
| 5879878 | 7b1eccd    |
| 5877531 | 7b1eccd    |
| 5877245 | 641ee8e    |
| 5877019 | 7cbfb83    |
| 5876864 | adc456e    |
| 5876671 | 9128b15    |
| 5876116 | 1f14ad5    |
+---------+------------+

To get a report issue the command
  ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g [ID]
where [ID] is the ID of the analysis you are interested in from the table above.

For example:
  ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g 5876116
to get the last report on that table 
➜  ghas-report-downloader git:(main) ✗
``` 

## To Be Done

### Short term

- [ ] Better details in the list reports function to help choose which report
- [ ] Actually implement downloading the report
- [ ] Better docs

### Mid term

- [ ] Support for GitHub Enterprise Server
- [ ] Support for GitHub AE

### Long term

- [ ] Interactivity to filter, choose and download multiple reports within one execution of the tool
