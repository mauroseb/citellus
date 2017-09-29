#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

if is_active ntpd; then
  ntpd=1
else
  ntpd=0
fi

if is_active chronyd ; then
  chronyd=1
else
  chronyd=0
fi

if [[ ntpd -eq 1 && chronyd -eq 1 ]] ; then
  echo "both ntpd and chrony are active" >&2
  exit $RC_FAILED
elif [[ ntpd -eq 1 || chronyd -eq 1 ]] ; then
  exit $RC_OKAY
else
  echo "both chrony or ntpd are not active" >&2
  exit $RC_FAILED
fi

exit $RC_SKIPPED
