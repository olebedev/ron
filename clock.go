package RON

import "time"

// hybrid calendar/logical clock
type Clock struct {
	offset    time.Duration
	lastSeen  UUID
	Mode      int
	MinLength int
}

const (
	CLOCK_CALENDAR = iota
	CLOCK_EPOCH    // TODO implement behavior
	CLOCK_LAMPORT
)

var MAX_BIT_GRAB uint64 = 1 << 20

func NewClock(replica uint64, mode, minLen int) Clock {
	origin := (replica & INT60_FULL) | UUID_EVENT_UPPER_BITS
	return Clock{lastSeen: UUID{0, origin}, Mode: mode, MinLength: minLen}
}

func time2uint(t time.Time) (i uint64) {
	months := (t.Year()-2010)*12 + int(t.Month()) - 1
	i |= uint64(months)
	days := t.Day() - 1
	i <<= 6
	i |= uint64(days)
	hours := t.Hour()
	i <<= 6
	i |= uint64(hours)
	minutes := t.Minute()
	i <<= 6
	i |= uint64(minutes)
	seconds := t.Second()
	i <<= 6
	i |= uint64(seconds)
	millis := t.Nanosecond() / 1000000
	i <<= 12
	i |= uint64(millis)
	i <<= 12
	return i
}

func trim_time(full, last uint64) uint64 {
	if full&PREFIX6 > last {
		if full&PREFIX5 > last {
			return full & PREFIX5
		} else {
			return full & PREFIX6
		}
	} else {
		if full&PREFIX8 > last {
			if full&PREFIX7 > last {
				return full & PREFIX7
			} else {
				return full & PREFIX8
			}
		} else {
			return full
		}
	}
}

func (clock *Clock) Time() UUID {
	var val uint64
	last := clock.lastSeen.Value
	switch clock.Mode {
	case CLOCK_CALENDAR:
		t := time.Now().Add(clock.offset).UTC()
		val = time2uint(t)
	case CLOCK_LAMPORT:
		val = last + 1
	case CLOCK_EPOCH:
		t := time.Now().Add(clock.offset).UTC()
		val = uint64(t.Unix()) << (4 * 6) // TODO define
	}
	if val <= last {
		val = last + 1
	} else {
		val = trim_time(val, last)
	}
	ret := NewEventUUID(val, clock.lastSeen.Origin)
	clock.See(ret)
	return ret
}

func (clock *Clock) See(uuid UUID) bool {
	if clock.lastSeen.Value < uuid.Value {
		clock.lastSeen.Value = uuid.Value
		return true
	} else {
		return false
	}
}

func (clock Clock) IsSane(uuid UUID) bool {
	switch clock.Mode {
	case CLOCK_LAMPORT:
		return clock.lastSeen.Value+MAX_BIT_GRAB > uuid.Value
	default:
		return true
	}
}

func uint2time(v uint64) time.Time {
	//var seq int = int(v & 4095)
	v >>= 12
	var ms int = int(v & 4095)
	v >>= 12
	var secs int = int(v & 63)
	v >>= 6
	var mins int = int(v & 63)
	v >>= 6
	var hours int = int(v & 63)
	v >>= 6
	var days int = int(v & 63)
	v >>= 6
	var months int = int(v & 4095)
	var month = months % 12
	var year = months / 12
	t := time.Date(year+2010, time.Month(month+1), days+1, hours, mins, secs, ms, time.UTC)
	return t
}
