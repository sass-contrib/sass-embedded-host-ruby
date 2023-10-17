# Design Overview

```
┌─────────────┐   ┌────────────┐                             ┌────────────┐   ┌─────────────────────┐
│             ├───►            │                             │            ├───►                     │
│ host thread │   │            │                             │            │   │ compilation isolate │
│             ◄───┤            │         write stdin         │            ◄───┤                     │
└─────────────┘   │    ruby    ├─────────────────────────────►    dart    │   └─────────────────────┘
                  │            │      from host threads      │            │
┌─────────────┐   │    sass    │                             │    sass    │   ┌─────────────────────┐
│             ├───►            │                             │            ├───►                     │
│ host thread │   │  embedded  │                             │  embedded  │   │ compilation isolate │
│             ◄───┤            │                             │            ◄───┤                     │
└─────────────┘   │    host    │                             │  compiler  │   └─────────────────────┘
                  │            │         read stdout         │            │
┌─────────────┐   │ dispatcher ◄─────────────────────────────┤ dispatcher │   ┌─────────────────────┐
│             ├───►            │      on polling thread      │            ├───►                     │
│ host thread │   │            │                             │            │   │ compilation isolate │
│             ◄───┤            │                             │            ◄───┤                     │
└─────────────┘   └────────────┘                             │            │   └─────────────────────┘
                                                             │            │
┌─────────────┐                                              │            │
│             │                          read stderr         │            │
│ ruby stderr ◄──────────────────────────────────────────────┤            │
│             │                       on polling thread      │            │
└─────────────┘                                              └────────────┘
```
