/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This file is part of the LibreOffice project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This file incorporates work covered by the following license notice:
 *
 *   Licensed to the Apache Software Foundation (ASF) under one or more
 *   contributor license agreements. See the NOTICE file distributed
 *   with this work for additional information regarding copyright
 *   ownership. The ASF licenses this file to you under the Apache
 *   License, Version 2.0 (the "License"); you may not use this file
 *   except in compliance with the License. You may obtain a copy of
 *   the License at http://www.apache.org/licenses/LICENSE-2.0 .
 */

#ifndef INCLUDED_SD_SOURCE_UI_INC_EVENTMULTIPLEXER_HXX
#define INCLUDED_SD_SOURCE_UI_INC_EVENTMULTIPLEXER_HXX

#include <sal/config.h>

#include <rtl/ref.hxx>
#include <svl/lstner.hxx>
#include <tools/link.hxx>
#include <o3tl/typed_flags_set.hxx>

#include <set>
#include <memory>

namespace sd {
class ViewShellBase;
}


enum class EventMultiplexerEventId : sal_uInt32 {
    /** The EventMultiplexer itself is being disposed.  Called for a live
        EventMultiplexer.  Removing a listener as response is not necessary,
        though.
    */
    Disposing             = 0x00000001,

    /** The selection in the center pane has changed.
    */
    EditViewSelection     = 0x00000002,

    /** The selection in the slide sorter has changed, regardless of whether
        the slide sorter is displayed in the left pane or the center pane.
    */
    SlideSortedSelection  = 0x00000004,

    /** The current page has changed.
    */
    CurrentPageChanged    = 0x00000008,

    /** The current MainViewShell (the ViewShell displayed in the center
        pane) has been removed.
    */
    MainViewRemoved       = 0x00000010,

    /** A new ViewShell has been made the MainViewShell.
    */
    MainViewAdded         = 0x00000020,

    /** A new ViewShell is being displayed in one of the panes.  Note that
        for the ViewShell in the center pane both this event type and
        EventId::MainViewAdded is broadcasted.
    */
    ViewAdded             = 0x00000040,

    /** The PaneManager is being destroyed.
    */
    PaneManagerDying      = 0x00000080,

    /** Edit mode was (or is being) switched to normal mode.  Find
        EventId::EditModeMaster below.
    */
    EditModeNormal        = 0x00000100,

    /** One or more pages have been inserted into or deleted from the model.
    */
    PageOrder             = 0x00000200,

    /** Text editing in one of the shapes in the MainViewShell has started.
    */
    BeginTextEdit         = 0x00000400,

    /** Text editing in one of the shapes in the MainViewShell has ended.
    */
    EndTextEdit           = 0x00000800,

    /** A UNO controller has been attached to the UNO frame.
    */
    ControllerAttached    = 0x00001000,

    /** A UNO controller has been detached to the UNO frame.
    */
    ControllerDetached    = 0x00002000,

    /** The state of a shape has changed.  The page is available in the user data.
    */
    ShapeChanged          = 0x00004000,

    /** A shape has been inserted to a page.  The page is available in the
        user data.
    */
    ShapeInserted         = 0x00008000,

    /** A shape has been removed from a page.  The page is available in the
        user data.
    */
    ShapeRemoved          = 0x00010000,

    /** A configuration update has been completed.
    */
    ConfigurationUpdated  = 0x00020000,

    /** Edit mode was (or is being) switched to master mode.
    */
    EditModeMaster        = 0x00040000,

    /** Some constants that make it easier to remove a listener for all
        event types at once.
    */
    AllMask               = 0x0007ffff,
    NONE                  = 0x00000000
};
namespace o3tl {
    template<> struct typed_flags<EventMultiplexerEventId> : is_typed_flags<EventMultiplexerEventId, 0x0007ffff> {};
}

namespace sd { namespace tools {

class EventMultiplexerEvent
{
public:
    EventMultiplexerEventId meEventId;
    const void* mpUserData;

    EventMultiplexerEvent (
        EventMultiplexerEventId eEventId,
        const void* pUserData);
};

/** This convenience class makes it easy to listen to various events that
    originally are broadcasted via different channels.

    There is usually one EventMultiplexer instance per ViewShellBase().
    Call the laters GetEventMultiplexer() method to get access to that
    instance.

    When a listener is registered it can specify the events it
    wants to be informed of.  This can be done with code like the following:

    mrViewShellBase.GetEventMultiplexer().AddEventListener (
        LINK(this,MasterPagesSelector,EventMultiplexerListener),
        EventMultiplexerEventId::MainViewAdded
        | EventMultiplexerEventId::MainViewRemoved);
*/
class EventMultiplexer
{
public:
    /** Create new EventMultiplexer for the given ViewShellBase object.
    */
    EventMultiplexer (ViewShellBase& rBase);
    ~EventMultiplexer();

    /** Add an event listener that will be informed about the specified
        event types.
        @param rCallback
            The callback to call as soon as one of the event specified by
            aEventTypeSet is received by the EventMultiplexer.
        @param aEventTypeSet
            A, possibly empty, set of event types that the listener wants to
            be informed about.
    */
    void AddEventListener (
        const Link<EventMultiplexerEvent&,void>& rCallback,
        EventMultiplexerEventId aEventTypeSet);

    /** Remove an event listener for the specified event types.
        @param aEventTypeSet
            The listener will not be called anymore for any of the event
            types in this set.  Use EventMultiplexerEventId::AllMask, the default value, to
            remove the listener for all event types it has been registered
            for.
    */
    void RemoveEventListener (
        const Link<EventMultiplexerEvent&,void>& rCallback,
        EventMultiplexerEventId aEventTypeSet = EventMultiplexerEventId::AllMask);

    /** This method is used for out-of-line events.  An event of the
        specified type will be sent to all listeners that are registered for
        that type.
        @param eEventId
            The type of the event.
        @param pUserData
            Some data sent to the listeners along with the event.
    */
    void MultiplexEvent(
        EventMultiplexerEventId eEventId,
        void* pUserData);

private:
    class Implementation;
    rtl::Reference<Implementation> mpImpl;
};

} } // end of namespace ::sd::tools

#endif

/* vim:set shiftwidth=4 softtabstop=4 expandtab: */
