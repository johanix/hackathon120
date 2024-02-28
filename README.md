# Generalized DNS Notifications @ Hackathon 119

Implementation of rapid and fully automated synchronization of DNS delegation data from child to parent.

## PROJECT

Add new functionality to a working nameserver implementation to
provide fully automatic management of delegation information
between child and parent zones according to the two drafts

- **draft-ietf-dnsop-generalized-notify-01**
- **draft-johani-dnsop-delegation-mgmt-via-ddns-02**

### Objective

The intent is to add functionality to an existing nameserver to make
it reach the point where changes in a child zone (changing **NS**,
rolling keys, etc) **rapidly** and **automatically** get reflected
in the parent zone. There are three mechanisms that may be explored:

1. **"NOTIFY + CDS/CSYNC":** Child sends a generalized notify to
  parent notification target.  Parent scans child zone for
  **CDS**/**CSYNC**, validates the result and updates parent zone
  according to policy.

2. **"DNS Update":** Child sends a **SIG(0)** signed DNS Update
  to parent update target. Parent does the same validation as in the
  **CDS**/**CSYNC** case and updates the parent zone according to
  policy.

3. **"Update via API":** We will simulate this by having child
  zones with notification or update targets be a "registrar" instead
  of the parent. The "registrar" figures out what change is needed in
  the parent zone for the child delegation and then performs that
  update via an API provided by the parent (rather than EPP, as we
  don't have any EPP infrastructure).

## EXISTING STUFF

1. There is a general implementation (in Go) of the proposed
  experimental "**DSYNC**" record type as a private RR type (a la
  **draft-ietf-dnsop-generalized-notify-01**). There is also
  support for conversion between **DSYNC** presentation format and
  RFC3597 presentation format (for "unknown RRtypes").

2. There is a simple authoritative nameserver (also written in Go)
  that supports inbound and outbound zone transfers, responding to
  different DNS queries, receive and send **NOTIFY** messages,
  etc. The nameserver already has an API, although the API will need
  to be extended with child update capabilities.

    The nameserver has support for **DSYNC** via the implementation
    above in the sense that **DSYNC** records may be published in zones
    without an RFC3597 conversion step.
 
3. There is a simple "dig" replacement (guess what, it's written in
  Go) that also has support for looking up **DSYNC** records.
 
Note that the existing code is just to provide something to start from. If
someone would rather work with some other code base or in some other
language, then that's also great.

## TASKS

### Child-side stuff

The child primary must notice when contents in the child zone that
affect the delegation changes. Then it needs to look up supported
synchronization schemes in the parent zone, choose one and inform the
parent via that mechanism.

**Implement support in the nameserver for:**

1. Detecting changes to delegation information (on zone reload or
   retransfer) and a hook to potentially do something when this happens.

2. Looking up what delegation synchronization "schemes" the parent
   zone supports.
     
3. Sending generalized notifications to the correct target.

4. Creating, signing and sending a DNS Update to the correct
   target.


## Parent-side stuff

The parent nameserver is already able to publish zones containing
**DSYNC** targets for children to utilize. The parent nameserver
should be extended be able to receive generalized notifications and
DNS Updates. The existing parent nameserver API support should be
extended to provide an endpoint that enables a "registrar" to make
updates on behalf of child zones.

**Implement support in the nameserver for:**

1. Receiving generalized notifications and have them trigger a
   **CDS** or **CSYNC** lookup and verification.

2. Receiving DNS Updates (including a suitably restrictive update
     policy) and verification of the data in the received update.

3. Synthezising responses to queries for "**child._dsync.parent.**" to
     return the **DSYNC** targets for the correct registrar (if any).
     This requires some sort of mapping between child zones and
     "registrars", including information about the registrars DSYNC
     targets.

4. Receiving updates to delegation information via a TLS-secured API
     call. Should include some sort of mapping for which set of child
     zones a particular client is allowed to update.


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


### Demo stuff

1. Design a nice demo to show off all the working functionality.


