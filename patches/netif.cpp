// Copyright (c) 2024 The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or https://www.opensource.org/licenses/mit-license.php.

#include <bitcoin-build-config.h> // IWYU pragma: keep

#include <common/netif.h>

#include <logging.h>
#include <netbase.h>
#include <util/check.h>
#include <util/sock.h>
#include <util/syserror.h>

#if defined(__linux__)
#include <linux/rtnetlink.h>
#elif defined(__FreeBSD__)
#include <osreldate.h>
#if __FreeBSD_version >= 1400000
// Workaround https://github.com/freebsd/freebsd-src/pull/1070.
#define typeof __typeof
#include <netlink/netlink.h>
#include <netlink/netlink_route.h>
#endif
#elif defined(WIN32)
#include <iphlpapi.h>
#elif defined(__APPLE__)
//#include <net/route.h>
#include <sys/sysctl.h>
#endif

namespace {

std::optional<CNetAddr> QueryDefaultGatewayImpl(sa_family_t)
{
    return std::nullopt;
}

}

std::optional<CNetAddr> QueryDefaultGateway(Network network)
{
    Assume(network == NET_IPV4 || network == NET_IPV6);

    sa_family_t family;
    if (network == NET_IPV4) {
        family = AF_INET;
    } else if(network == NET_IPV6) {
        family = AF_INET6;
    } else {
        return std::nullopt;
    }

    std::optional<CNetAddr> ret = QueryDefaultGatewayImpl(family);

    // It's possible for the default gateway to be 0.0.0.0 or ::0 on at least Windows
    // for some routing strategies. If so, return as if no default gateway was found.
    if (ret && !ret->IsBindAny()) {
        return ret;
    } else {
        return std::nullopt;
    }
}


std::vector<CNetAddr> GetLocalAddresses()
{
    std::vector<CNetAddr> addresses;
#ifdef WIN32
    char pszHostName[256] = "";
    if (gethostname(pszHostName, sizeof(pszHostName)) != SOCKET_ERROR) {
        addresses = LookupHost(pszHostName, 0, true);
    }
#elif (HAVE_DECL_GETIFADDRS && HAVE_DECL_FREEIFADDRS)
    struct ifaddrs* myaddrs;
    if (getifaddrs(&myaddrs) == 0) {
        for (struct ifaddrs* ifa = myaddrs; ifa != nullptr; ifa = ifa->ifa_next)
        {
            if (ifa->ifa_addr == nullptr) continue;
            if ((ifa->ifa_flags & IFF_UP) == 0) continue;
            if ((ifa->ifa_flags & IFF_LOOPBACK) != 0) continue;
            if (ifa->ifa_addr->sa_family == AF_INET) {
                struct sockaddr_in* s4 = (struct sockaddr_in*)(ifa->ifa_addr);
                addresses.emplace_back(s4->sin_addr);
            } else if (ifa->ifa_addr->sa_family == AF_INET6) {
                struct sockaddr_in6* s6 = (struct sockaddr_in6*)(ifa->ifa_addr);
                addresses.emplace_back(s6->sin6_addr);
            }
        }
        freeifaddrs(myaddrs);
    }
#endif
    return addresses;
}
