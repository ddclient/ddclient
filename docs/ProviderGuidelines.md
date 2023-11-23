# Provider implementations

Author: [@LenardHess](https://github.com/LenardHess/)\
Date: 2023-11-23

This document is meant to detail the mechanisms that provider implementation shall use. It differentiates between new and legacy provider implementations. The former are adhering to the IPv6 support updates being done to ddclient, the legacy ones are from before that update.

## New provider Implementation
1. Grab the IP(s) from $config{$host}{'wantipv4'} and/or $config{$host}{'wantipv6'}
2. Optional: Query the provider for the current IP record(s). If they are already good, skip updating IP record(s)
3. Update the IP record(s).
4. If successful (or if the records were already good):
    - Set 'status-ipv4' and/or 'status-ipv6' to 'good'
    - Set 'ipv4' and/or 'ipv6' to the IP that has been set
    - Set 'mtime' to the current time
5. If not successful:
    - Set 'status-ipv4' and/or 'status-ipv6' to an error message
    - Set 'atime' to the current time

The new provider implementation should not set 'status' nor 'ip'. They're part of the legacy infrastructure and ddclient will take care of setting them correctly.

## Legacy provider implementations
1. Grab the IP from $config{$host}{'wantip'}
2. Optional: Query the provider for the current IP record. If it is already good, skip updating IP record
3. Update the IP record.
4. If successful (or if the record was already good):
    - Set 'status' to 'good'
    - Set 'ip' to the IP that has been set
    - Set 'mtime' to the current time
5. If not successful:
    - Set 'status' to an error message
    - Set 'atime' to the current time

# ToDo
- Decide/Inquire whether services prefer querying the IP first. Then decide whether to make it mandatory.
- Write guidelines on checking existing records (i.e. check TTL as well?).
- Start a list of providers and their implementation state
- Add more details to this document
    - Whether 'wantip*' ought to be deleted when read or not.
