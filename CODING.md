# Rapid Automated Synchronization of DNS Delegation Data From Child to Parent

Implementation of rapid and fully automated synchronization of DNS delegation data from child to parent.

## How to get started:

You will need to have a reasonably modern version of the Go compiler installed. I suggest
you go with v1.21, but a slightly older one will likely also work find.

1. Clone the repo github.com/johanix/tdns.

   This contains the source of three tools:
  - **tdnsd**, a simple authoritative nameserver
  - **tdns-cli**, a CLI tool to interact with **tdnsd**
  - **dog**, another CLI tool with funcionality remarkably similar to a simple
    version of the well-known "dig" utility that ISC provides.

2. Clone the repo github.com/johanix/dns. 

   This contains a slightly modified version of the normal Go DNS library written by
   Miek Gieben. The changes are just to make the library accept NOTIFY messages with
   other RRtypes than SOA and to slightly relax the restrictions on the number of 
   records in the different sections of DNS updates messages accepted by the library.

3. If you just put the "dns" repo next to the "tdns" repo, you don't need this step.
   If you put it in a different directly, you need to add a `replace` directive in
   the `go.mod` file for each of the different tools in the tdns repo:

   ```
      replace github.com/miekg/dns => where/you/put/dns
   ```

   so that all references to the normal DNS library are replaced by our local version. 

4. Try to build everything:

```
(cd tdns ; make)
```

