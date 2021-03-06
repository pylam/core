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

#ifndef INCLUDED_SVTOOLS_SOURCE_INC_PROVIDER_HXX
#define INCLUDED_SVTOOLS_SOURCE_INC_PROVIDER_HXX

#include <cppuhelper/implbase.hxx>
#include <com/sun/star/lang/XServiceInfo.hpp>
#include <com/sun/star/graphic/XGraphicProvider.hpp>
#include <com/sun/star/awt/XBitmap.hpp>

namespace {

class GraphicProvider : public ::cppu::WeakImplHelper< css::graphic::XGraphicProvider,
                                                        css::lang::XServiceInfo >
{
public:

    GraphicProvider();
    virtual ~GraphicProvider() override;

protected:

    // XServiceInfo
    virtual OUString SAL_CALL getImplementationName() throw( css::uno::RuntimeException, std::exception ) override;
    virtual sal_Bool SAL_CALL supportsService( const OUString& ServiceName ) throw( css::uno::RuntimeException, std::exception ) override;
    virtual css::uno::Sequence< OUString > SAL_CALL getSupportedServiceNames() throw( css::uno::RuntimeException, std::exception ) override;

    // XTypeProvider
    virtual css::uno::Sequence< css::uno::Type > SAL_CALL getTypes(  ) throw(css::uno::RuntimeException, std::exception) override;
    virtual css::uno::Sequence< sal_Int8 > SAL_CALL getImplementationId(  ) throw(css::uno::RuntimeException, std::exception) override;

    // XGraphicProvider
    virtual css::uno::Reference< css::beans::XPropertySet > SAL_CALL queryGraphicDescriptor( const css::uno::Sequence< css::beans::PropertyValue >& MediaProperties ) throw (css::io::IOException, css::lang::IllegalArgumentException, css::lang::WrappedTargetException, css::uno::RuntimeException, std::exception) override;
    virtual css::uno::Reference< css::graphic::XGraphic > SAL_CALL queryGraphic( const css::uno::Sequence< css::beans::PropertyValue >& MediaProperties ) throw (css::io::IOException, css::lang::IllegalArgumentException, css::lang::WrappedTargetException, css::uno::RuntimeException, std::exception) override;
    virtual void SAL_CALL storeGraphic( const css::uno::Reference< css::graphic::XGraphic >& Graphic, const css::uno::Sequence< css::beans::PropertyValue >& MediaProperties ) throw (css::io::IOException, css::lang::IllegalArgumentException, css::lang::WrappedTargetException, css::uno::RuntimeException, std::exception) override;

private:

    static css::uno::Reference< css::graphic::XGraphic > implLoadMemory( const OUString& rResourceURL );
    static css::uno::Reference< css::graphic::XGraphic > implLoadGraphicObject( const OUString& rResourceURL );
    static css::uno::Reference< css::graphic::XGraphic > implLoadResource( const OUString& rResourceURL );
    static css::uno::Reference< css::graphic::XGraphic > implLoadRepositoryImage( const OUString& rResourceURL );
    static css::uno::Reference< css::graphic::XGraphic > implLoadBitmap( const css::uno::Reference< css::awt::XBitmap >& rBitmap );
    static css::uno::Reference< css::graphic::XGraphic > implLoadStandardImage( const OUString& rResourceURL );
};

}

#endif

/* vim:set shiftwidth=4 softtabstop=4 expandtab: */
