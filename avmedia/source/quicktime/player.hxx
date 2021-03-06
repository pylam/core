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

#ifndef INCLUDED_AVMEDIA_SOURCE_QUICKTIME_PLAYER_HXX
#define INCLUDED_AVMEDIA_SOURCE_QUICKTIME_PLAYER_HXX

#include "quicktimecommon.hxx"
#include <cppuhelper/implbase.hxx>
#include "com/sun/star/media/XPlayer.hpp"

namespace avmedia { namespace quicktime {

class Player : public ::cppu::WeakImplHelper< css::media::XPlayer,
                                              css::lang::XServiceInfo >
{
public:

    Player( const css::uno::Reference< css::lang::XMultiServiceFactory >& rxMgr );
    virtual ~Player();

    bool create( const OUString& rURL );

    // XPlayer
    virtual void SAL_CALL start(  ) throw (css::uno::RuntimeException) override;
    virtual void SAL_CALL stop(  ) throw (css::uno::RuntimeException) override;
    virtual sal_Bool SAL_CALL isPlaying(  ) throw (css::uno::RuntimeException) override;
    virtual double SAL_CALL getDuration(  ) throw (css::uno::RuntimeException) override;
    virtual void SAL_CALL setMediaTime( double fTime ) throw (css::uno::RuntimeException) override;
    virtual double SAL_CALL getMediaTime(  ) throw (css::uno::RuntimeException) override;
    virtual void SAL_CALL setPlaybackLoop( sal_Bool bSet ) throw (css::uno::RuntimeException) override;
    virtual sal_Bool SAL_CALL isPlaybackLoop(  ) throw (css::uno::RuntimeException) override;
    virtual void SAL_CALL setMute( sal_Bool bSet ) throw (css::uno::RuntimeException) override;
    virtual sal_Bool SAL_CALL isMute(  ) throw (css::uno::RuntimeException) override;
    virtual void SAL_CALL setVolumeDB( sal_Int16 nVolumeDB ) throw (css::uno::RuntimeException) override;
    virtual sal_Int16 SAL_CALL getVolumeDB(  ) throw (css::uno::RuntimeException) override;
    virtual css::awt::Size SAL_CALL getPreferredPlayerWindowSize(  ) throw (css::uno::RuntimeException) override;
    virtual css::uno::Reference< css::media::XPlayerWindow > SAL_CALL createPlayerWindow( const css::uno::Sequence< css::uno::Any >& aArguments ) throw (css::uno::RuntimeException) override;
    virtual css::uno::Reference< css::media::XFrameGrabber > SAL_CALL createFrameGrabber(  ) throw (css::uno::RuntimeException) override;
    // XServiceInfo
    virtual OUString SAL_CALL getImplementationName(  ) throw (css::uno::RuntimeException) override;
    virtual sal_Bool SAL_CALL supportsService( const OUString& ServiceName ) throw (css::uno::RuntimeException) override;
    virtual css::uno::Sequence< OUString > SAL_CALL getSupportedServiceNames(  ) throw (css::uno::RuntimeException) override;

    QTMovie* getMovie();

private:
    css::uno::Reference< css::lang::XMultiServiceFactory > mxMgr;

    OUString                maURL;

    QTMovie                 *mpMovie;      // the Movie object

    float                   mnUnmutedVolume;
    double                  mnStopTime;

    bool                    mbMuted;
    bool                    mbInitialized;
};

} // namespace quicktime
} // namespace avmedia

#endif // INCLUDED_AVMEDIA_SOURCE_QUICKTIME_PLAYER_HXX

/* vim:set shiftwidth=4 softtabstop=4 expandtab: */
