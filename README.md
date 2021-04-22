# ghas-report-downloader

Goal is to list reports and allow the user to select the report they want to download. Also to teach myself some Ruby.

Reports will be downloaded in `.sarif` format and can be viewed in a IDE's SARIF viewer plugin

GitHub.com / GitHub Enterprise Cloud support only at this point in time

## Requirements

To run this script, please set the following environment variables:

- GITHUB_PAT: A Personal Access Token (PAT) for your account

## To run:

``` zsh
bundle install
./ghasrd.rb
```
### Listing available reports

``` zsh
➜  ghas-report-downloader git:(main) ✗ ./ghasrd.rb -l -o affrae -r quickjavahelloworldmultimodule
Listing available reports for affrae/quickjavahelloworldmultimodule
+---------+------------------------------------------+
| ID      | Commit SHA                               |
+---------+------------------------------------------+
| 6516422 | 1161a606b66f05675f2acfde9a536b329a121fe2 |
| 6516391 | 7e79a09b9a04b370b15978ee9fde944368b62692 |
| 6516390 | 4cf767994bb3ad0c7d69832fe84677d786821888 |
| 6516388 | c920fc218e4394b420f6c399f0fcf581f1fb8685 |
| 6516361 | 6b178ddc4ce7a5489799b991c2ff6fda1f9fe129 |
| 6326184 | 7b1eccd8747a28765aab23ce1c1ca5400edfec45 |
| 6089337 | 7b1eccd8747a28765aab23ce1c1ca5400edfec45 |
| 5881321 | 18af1787e30aaba91f5b82a47a9506e67c26cb90 |
| 5881308 | fb104c512307caa387995f9c056a69ba53999c1d |
| 5881292 | 0cebba7fd6ad31425a13ccec07be87b50705e598 |
| 5881218 | ebca64ed9d116edd92ba1cfca57354b733081c30 |
| 5879878 | 7b1eccd8747a28765aab23ce1c1ca5400edfec45 |
| 5877531 | 7b1eccd8747a28765aab23ce1c1ca5400edfec45 |
| 5877245 | 641ee8e1d9c5ee4f2e499b582eeff938d560796a |
| 5877019 | 7cbfb8371f5ff11cbfc99901258f127317da7de6 |
| 5876864 | adc456e256d5a38f4ca812a3baf34c45e6d9965d |
| 5876671 | 9128b15ffb501e491ea2d9bb134a41428bc46871 |
| 5876116 | 1f14ad563dfa6f785b087fd8f426982974d846eb |
+---------+------------------------------------------+

To get a report issue the command
  ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g [ID]
where [ID] is the ID of the analysis you are interested in from the table above.

For example:
  ghasrd.rb -o affrae -r quickjavahelloworldmultimodule -g 5876116
to get the last report on that table 
➜  ghas-report-downloader git:(main) ✗
``` 

## To Be Done

- [ ] Better details in the list reports function to help choose which report
- [ ] Download the report
- [ ] Better docs
- [ ] Support for GitHub Enterprise Server
- [ ] Support for GitHub AE
- [ ] Interactivity to filter, choose and download within one execution of the tool
