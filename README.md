# Rapid Automated Synchronization of DNS Delegation Data From Child to Parent


## PROJECT

Add new functionality to a simple but working nameserver implementation to
enable fully automatic synchronization of delegation information
from child zone to parent zone.

The goal is to make synchronization both rapid and fully automated for
both DNSSEC signed and unsigned child zones.

The specification for what should be built is based on the two drafts:

- **draft-ietf-dnsop-generalized-notify-02**
- **draft-johani-dnsop-delegation-mgmt-via-ddns-02**

**Note:** There are quite a lot of separate tasks listed below. There
should be something for everyone interested. Some tasks are quite
small while others require a bit more work.

### Objective

The intent is to add functionality to an existing nameserver to make
it reach the point where changes in a child zone (changing **NS**,
rolling keys, etc) **rapidly** and **automatically** get reflected
in the parent zone. There are three mechanisms that may be explored:

1. **"NOTIFY + CDS/CSYNC lookup":** Child sends a generalized notify
  (NOTIFY(CDS) or NOTIFY(CSYNC) to parent notification target. Parent
  looks up **CDS** or **CSYNC** record in child zone, validates the
  result and updates parent zone according to policy.

2. **"DNS Update":** Child sends a **SIG(0)** signed DNS Update
  to parent update target. Parent does the same validation as in the
  **CDS**/**CSYNC** case and updates the parent zone according to
  policy.

3. **"Update via API":** If there is time for this alternative, then it
  will be simulated by having child zones with notification or update
  targets be a "registrar" instead of the parent. The "registrar" figures
  out what change is needed in the parent zone for the child delegation
  and then performs that update via an API provided by the parent (rather
  than EPP, as we don't have any EPP infrastructure).

## EXISTING STUFF

1. There is a general implementation (written in Go) of the proposed
  experimental "**DSYNC**" record type as a private RR type (a la
  **draft-ietf-dnsop-generalized-notify-02**). There is also
  support for conversion between **DSYNC** presentation format and
  RFC3597 presentation format (for "unknown RRtypes"), if needed.

2. There is a simple authoritative nameserver called `tdnsd` (written in Go)
  that supports inbound and outbound zone transfers, responding to
  different DNS queries, receive and send **NOTIFY** messages,
  etc.

    - `tdnsd` has an API, although the API will need
    to be extended with child update capabilities. It also has preliminary
    support for online signing, as well as sending and receiving DNS Updates.

    - `tdnsd` has support for **DSYNC** via the implementation
    above in the sense that **DSYNC** records may be published in zones
    without an RFC3597 conversion step.

    - `tdnsd` supports inbound DNS UPDATEs, both for (in a child role)
    updating authoritative zone data and (in a parent role) updating 
    child delegation data.

3. There is a CLI management tool for `tdnsd` called `tdns-cli`.

   - `tdns-cli` has a range of different commands to add/delete/list 
  both SIG(0) and DNSSEC private keys in the `tdnsd keystore`.

   - `tdns-cli` has a range of commands to add/delete/list SIG(0) public
   SIG(0) keys in the `tdnsd truststore`. It is also possible to manage
   whether a particular SIG(0) key is *trusted* (as opposed to *known*
   or *validated*).

   - `tdns-cli` is able to create, sign and send DNS UPDATE messages
   (typically to `tdnsd`, but not necessarily). In particular, it is
   able to send UPDATEs containing new record types like **DSYNC** and
   **DELEG**, that are not supported by the well-known tool `nsupdate`.
 
4. There is a simple "**dig**" replacement called **dog** (also written 
   in Go) that has
   support for looking up and presenting **DSYNC** records, either in
   response to specific queries for **DSYNC** records, or as part of a
   zone transfer. **dog** also supports **DELEG** records.

The code for the nameserver and CLI tools is in the Github repo is in the Github repo [https://github.com/johanix/tdns.git](https://github.com/johanix/tdns.git). Please
take a look att the file CODING.md here in this repo, as it explains how to set
things up to be able to build things.
 
Note that the existing code is just to provide something to start from. If
someone would rather work with some other code base or in some other
language, then that's also great.

## TASKS

### Child-side functionality:

The child primary must notice when contents in the child zone that
affect the delegation changes. Then it needs to look up supported
synchronization schemes in the parent zone, choose one and inform the
parent via that mechanism.

**Implement support in the nameserver for:**

1. **[DONE]** Detecting changes to delegation information (on zone reload or
   retransfer) and a hook to potentially do something when this happens.

2. **[DONE]** Looking up what delegation synchronization "schemes" the parent
   zone supports.
     
3. Publish an appropriate CSYNC record in the zone.
   
4. Sending generalized notifications to the correct target.

5. Publish an appropriate (i.e. a key for which TDNSD has the private key) KEY record in the zone.

6. **[DONE]** A keystore for child private SIG(0) keys to be used to sign DNS Updates.

7. **[DONE]** Creating, signing and sending a DNS Update to the correct
   target.


## Parent-side functionality:

The parent nameserver is already able to publish zones containing
**DSYNC** targets for children to utilize. The parent nameserver
should be extended be able to receive generalized notifications and
DNS Updates. The existing parent nameserver API support should be
extended to provide an endpoint that enables a "registrar" to make
updates on behalf of child zones.

**Implement support in the nameserver for:**

1. Receiving generalized notifications and have them trigger a
   **CDS** or **CSYNC** lookup and verification.

2. **[DONE]** Receiving DNS Updates (including implementation of a suitably
   restrictive update policy) and verification of the data in the
   received update.

3. **[DONE]** A datastore for child public keys (used for validation of DNS Updates).

4. **[DONE]** A datastore for updated child delegation information.

5. Synthezising responses to queries for "**child._dsync.parent.**" to
   return the **DSYNC** targets for the correct registrar (if any).
   This requires some sort of mapping between child zones and
   "registrars", including information about the registrars DSYNC
   targets.

6. Receiving updates to delegation information via a TLS-secured API
   call. Should include some sort of mapping for which set of child
   zones a particular client is allowed to update.

7. DNSSEC-validation of signed data in a child zone. I.e. for the parent
   to be able to trust CDS/CSYNC/NS/glue RRsets in the child it must be able
   to verify their authenticity.

## General functionality:

**Implement or improve the support for:**

1. Signing and re-signing RRsets that are modified.

2. Providing authenticated negative responses via
   so-called "DNSSEC black lies".

3. Freeze/thaw logic to enable modifications to primary zones 
   to optionally be written back to the zone file.

4. Complete zone signing, including publication of the DNSKEY RRset,
   correctly sign different RRsets with either ZSKs or KSKs, as
   appropriate.

<!---
## Registrar-side stuff

The intended model for a registrar is that if the generalized
notifications and/or some other scheme is sent to the registrar, then
it will do whatever verifications it deems necessary and if successful
translate this into an EPP transaction.

The "registrar" primary will be the same implementation as the parent
(and child for that matter). When it gets support for receving
generalized notifications and/or DNS Updates it should be able to act
as a "registrar" rather than as a "parent primary". I.e. instead of
updating the parent zone it should send the data to the parent. We
don't have EPP, so we will simulate that via the parent-side API
instead.

**Implement support in the nameserver for:**

1. A "registrar" zone type. Zones managed as a registrar will not be
     served, but rather only the delegation information will be
     maintained.

2. The client side of the parent API to make updates to the
     delegation information for child zones in the parent zone.

3. "Translation" from an incoming (either
     **NOTIFY** + subsequent lookup and validation of a
     **CDS**/**CSYNC** or a DNS Update) to an API transaction to
     update the parent zone.
--->

### Demo stuff

1. Design a nice demo to show off all the working functionality.


