#!/usr/bin/python3
# Changes to the installer's pages (Anaconda's web interface, index.js.gz), run by build.sh:
#  - the orange "Pre-release" badge reads "Beta", and its popup says EasySpeakOS is in beta and where to report
#    problems, instead of "Do NOT use this software for any critical work";
#  - the "Send us feedback" block with Fedora's QR code and link is gone from the last page;
#  - "Report issue" (in the menu, and in the window shown if the installer hits an error) opens a new issue on
#    EasySpeakOS's GitHub page, filled in with the error details, instead of Red Hat's Bugzilla. The Bugzilla
#    sign-in (API key) step is removed.
# Each change must match exactly once. If a new installer version changes its pages, this stops the build instead
# of shipping a half-changed installer.
import gzip
import sys

ISSUES = "https://github.com/ctsdownloads/easyspeak-os/issues"
path = sys.argv[1]
js = gzip.open(path, "rt", encoding="utf-8").read()


def fail(msg):
    sys.exit(f"ERROR: installer pages: {msg}")


def swap(old, new, what):
    global js
    n = js.count(old)
    if n != 1:
        fail(f"{what}: expected once, found {n} times")
    js = js.replace(old, new)


# Beta badge and its popup
swap('gg("Pre-release")', 'gg("Beta")', "badge")
swap('gg("This is unstable, pre-release software")', 'gg("EasySpeakOS is in beta")', "badge popup title")
swap('gg("Notice: This is pre-released software that is intended for development and testing purposes only. '
     'Do NOT use this software for any critical work or for production environments.")',
     f'gg("Please report problems at {ISSUES[8:]}")', "badge popup text")
swap(',wo.default.createElement(wt,{component:Nr.p},gg("By continuing to use this software, you understand and '
     'accept the risks associated with pre-released software, that you intend to use this for testing and '
     'development purposes only and are willing to report any bugs or issues in order to enhance this work.")),'
     'wo.default.createElement(wt,{component:Nr.p},gg("If you do not understand or accept the risks, then please '
     'exit this program."))', '', "badge popup warnings")

# Fedora's feedback block (QR code and link) on the last page
swap('(e==="success"||e==="danger")&&Le.default.createElement(R3,null)', '!1', "feedback block")
swap('(t?"https://":"extlink://")+"discussion.fedoraproject.org/tag/anaconda"},"https://discussion.fedoraproject.org/tag/anaconda"',
     f'(t?"https://":"extlink://")+"{ISSUES[8:]}"}},"{ISSUES}"', "feedback link")

# Problem reports go to GitHub. The link carries the error details as the new issue's title and text.
swap('var E0="https://bugzilla.redhat.com"', f'var E0="{ISSUES}"', "report address")
swap('RF=(t,e="anaconda")=>{let o={component:e,...t},r=new URL(E0);return r.pathname="enter_bug.cgi",'
     'Object.keys(o).map(l=>r.searchParams.append(l,o[l])),r.href}',
     f'RF=(t,e="anaconda")=>"{ISSUES}/new"', "report link")
swap('o=[{length:256,param:"short_desc"},{length:7836,param:"comment"}]',
     'o=[{length:256,param:"title"},{length:7000,param:"body"}]', "report length limits")
swap('r=e.searchParams.get("comment")||"";return e.searchParams.set("comment",',
     'r=e.searchParams.get("body")||"";return e.searchParams.set("body",', "report log note")
swap('o&&a.searchParams.append("short_desc",o)', 'o&&a.searchParams.append("title",o)', "report title")
swap('i&&a.searchParams.append("comment",i)', 'i&&a.searchParams.append("body",i)', "report text")
swap('Mt("Report an issue or provide feedback by opening the Bugzilla bug entry form $0.")',
     'Mt("Report a problem or give feedback on EasySpeakOS\'s GitHub page: $0.")', "report text in the menu")
swap('Mt("Prefer to report manually? $0")', 'Mt("Report this problem on EasySpeakOS\'s GitHub page: $0")',
     "report text after an error")
swap('Mt("Open Bugzilla bug entry form")', 'Mt("open a new issue")', "report link text after an error")
# After an error: no Bugzilla API key step and no Next button leading to it, only the details and the GitHub link.
swap('st.default.createElement(qj,{bugCreationError:p,bugzillaApiKey:f,idPrefix:o,onApiKeyChange:b}),'
     'st.default.createElement(nn,null),', '', "Bugzilla sign-in step")
swap('v===1&&st.default.createElement(it,{key:"next"', '!1&&st.default.createElement(it,{key:"next"',
     "Bugzilla sign-in Next button")

# What must not be left anywhere a user can reach
for gone in ('gg("Pre-release")', "fedoraproject.org/", "createElement(R3,", "createElement(qj,",
             "Bugzilla bug entry form", 'pathname="enter_bug.cgi"'):
    if gone in js:
        fail(f"still contains {gone}")

with gzip.open(path + ".new", "wt", encoding="utf-8", compresslevel=9) as f:
    f.write(js)
print(f"installer pages changed: Beta badge, no Fedora feedback block, problem reports go to {ISSUES}")
