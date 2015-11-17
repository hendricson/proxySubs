# Set of perl subs to allow perl programs access contents of web pages via intermediate servers (proxies)

There're subs to load proxy lists from a local file, a database, and remote URL (*http://yoursite/proxylist.txt*).

See **demo.pl** for usage example.

## HOW TO USE

1. Include **proxySubs.pl** in your scripts and replace *get* function with *getHTTPContents* everywhere in your scripts.

2. Please note that *getHTTPContents* returns a list of *(HTMLText, status)* and status is equal to zero if the script could not obtain the HTML contents.
