/* -*-objc-*-
   GSMarkupTagTextLabel.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2002

   This file is part of GNUstep Renaissance

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
@import "GSMarkupTagView.j"


@implementation FSLabel : CPTextField

- (BOOL)acceptsFirstResponder
{
    return NO;
}

// Labels in vertikalen Boxen standardmäßig linksbündig ausrichten
- (GSAutoLayoutAlignment)autolayoutDefaultHorizontalAlignment
{
    return GSAutoLayoutAlignMin;
}

// Labels in horizontalen Boxen standardmäßig vertikal zentrieren
- (GSAutoLayoutAlignment)autolayoutDefaultVerticalAlignment
{
    return GSAutoLayoutAlignCenter;
}

@end


@implementation GSMarkupTagLabel : GSMarkupTagView

+ (CPString)tagName
{
    return @"label";
}

+ (Class)platformObjectClass
{
    return [FSLabel class];
}

+ (CPArray)localizableAttributes
{
    return [CPArray arrayWithObjects:@"stringValue", @"title", nil];
}

- (id)initPlatformObject:(id)platformObject
{
    platformObject = [super initPlatformObject:platformObject];

    [platformObject setEditable:NO];
    [platformObject setBezeled:NO];
    [platformObject setBordered:NO];

    /* -----------------------------------------------------------
     * 1. MARGIN / BORDER AN DIE AUTOLAYOUT-CONTAINER ÜBERGEBEN
     * ----------------------------------------------------------- */
    var marginStr = [_attributes objectForKey:@"margin"] || [_attributes objectForKey:@"border"];
    if (marginStr)
    {
        var marginVal = parseFloat(marginStr);
        if (!isNaN(marginVal))
        {
            // Mappt 'margin' auf border/hborder/vborder, damit HBox und VBox das Padding berechnen
            if (![_attributes objectForKey:@"border"])
                [_attributes setObject:marginStr forKey:@"border"];
            if (![_attributes objectForKey:@"hborder"])
                [_attributes setObject:marginStr forKey:@"hborder"];
            if (![_attributes objectForKey:@"vborder"])
                [_attributes setObject:marginStr forKey:@"vborder"];

            [platformObject setValue:CGInsetMake(marginVal, marginVal, marginVal, marginVal) forThemeAttribute:@"content-inset"];
        }
    }

    /* -----------------------------------------------------------
     * 2. TEXT AUFLÖSEN (stringValue -> title -> Tag-Content)
     * ----------------------------------------------------------- */
    var labelText = [self localizedStringValueForAttribute:@"stringValue"];
    if (labelText == nil || [labelText length] === 0)
    {
        labelText = [self localizedStringValueForAttribute:@"title"];
    }
    if ((labelText == nil || [labelText length] === 0) && [_content count] > 0)
    {
        var s = [_content objectAtIndex:0];
        if (s != nil && [s isKindOfClass:[CPString class]])
        {
            labelText = s;
        }
    }

    if (labelText != nil)
    {
        [platformObject setStringValue:labelText];
    }

    /* -----------------------------------------------------------
     * 3. FONT & FONTSIZE (z.B. font="bold" size="15")
     * ----------------------------------------------------------- */
    var fontSize = 12.0;
    var sizeAttr = [_attributes objectForKey:@"size"];
    if (sizeAttr)
    {
        var parsedSize = parseFloat(sizeAttr);
        if (!isNaN(parsedSize))
            fontSize = parsedSize;
    }

    var fontAttr = [_attributes objectForKey:@"font"];
    var resolvedFont = nil;

    if (fontAttr)
    {
        if ([fontAttr isEqualToString:@"bold"] || [fontAttr isEqualToString:@"boldSystemFont"])
        {
            resolvedFont = [CPFont boldSystemFontOfSize:fontSize];
        }
        else
        {
            resolvedFont = [CPFont fontWithName:fontAttr size:fontSize] || [CPFont systemFontOfSize:fontSize];
        }
    }
    else if (sizeAttr)
    {
        resolvedFont = [CPFont systemFontOfSize:fontSize];
    }

    if (resolvedFont)
    {
        [platformObject setFont:resolvedFont];
    }

    /* -----------------------------------------------------------
     * 4. TEXTFARBE & HINTERGRUNDFARBE (inkl. '#'-Hex-Codes)
     * ----------------------------------------------------------- */
    var colorStr = [_attributes objectForKey:@"textColor"] || [_attributes objectForKey:@"color"];
    if (colorStr)
    {
        var resolvedColor = [self parseColorString:colorStr];
        if (resolvedColor)
            [platformObject setTextColor:resolvedColor];
    }

    var bgStr = [_attributes objectForKey:@"backgroundColor"] || [_attributes objectForKey:@"bgColor"];
    if (bgStr)
    {
        var resolvedBg = [self parseColorString:bgStr];
        if (resolvedBg)
        {
            [platformObject setBackgroundColor:resolvedBg];
            [platformObject setDrawsBackground:YES];
        }
    }
    else
    {
        [platformObject setDrawsBackground:NO];
    }

    /* -----------------------------------------------------------
     * 5. WRAPPING & AUSRICHTUNG
     * ----------------------------------------------------------- */
    var wordWrap = [self boolValueForAttribute:@"wordWrap"];
    [platformObject setLineBreakMode:(wordWrap == 1) ? CPLineBreakByWordWrapping : CPLineBreakByClipping];

    var selectable = [self boolValueForAttribute:@"selectable"];
    [platformObject setSelectable:(selectable == 0) ? NO : YES];

    var align = [_attributes objectForKey:@"textAlignment"] || [_attributes objectForKey:@"align"];
    if (align)
    {
        if ([align isEqualToString:@"center"])
            [platformObject setAlignment:CPCenterTextAlignment];
        else if ([align isEqualToString:@"right"])
            [platformObject setAlignment:CPRightTextAlignment];
        else if ([align isEqualToString:@"left"])
            [platformObject setAlignment:CPLeftTextAlignment];
    }

    return platformObject;
}

- (id)postInitPlatformObject:(id)platformObject
{
    platformObject = [super postInitPlatformObject:platformObject];

    // Garantiert, dass sich die Box exakt an die Schriftgröße und den Text anpasst
    [platformObject sizeToFit];

    return platformObject;
}

- (CPColor)parseColorString:(CPString)aColorString
{
    if (!aColorString || [aColorString length] === 0)
        return nil;

    var clean = aColorString;
    if ([clean hasPrefix:@"#"])
        clean = [clean substringFromIndex:1];

    // A. Benannte Farben (z. B. "white", "black", "red", "gray")
    var selName = clean + "Color";
    var sel = CPSelectorFromString(selName);
    if (sel && [CPColor respondsToSelector:sel])
        return [CPColor performSelector:sel];

    // B. 3-stellige Hex-Codes (z. B. "FFF" oder "333")
    if (clean.length === 3)
    {
        var r = clean.charAt(0), g = clean.charAt(1), b = clean.charAt(2);
        clean = r + r + g + g + b + b;
    }

    // C. 6- oder 8-stellige Hex-Codes (z. B. "F5F7F8" oder "333333")
    if (clean.length === 6 || clean.length === 8)
    {
        var r = parseInt(clean.substring(0, 2), 16) / 255.0;
        var g = parseInt(clean.substring(2, 4), 16) / 255.0;
        var b = parseInt(clean.substring(4, 6), 16) / 255.0;
        var a = (clean.length === 8) ? (parseInt(clean.substring(6, 8), 16) / 255.0) : 1.0;

        if (!isNaN(r) && !isNaN(g) && !isNaN(b))
            return [CPColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    }

    return nil;
}

@end


// --------------------------------------------------------------------------------
// KATEGORIE-PATCH: Ermöglicht '#'-Farbcodes auch für <hbox backgroundColor="#F5F7F8">
// --------------------------------------------------------------------------------

@implementation GSMarkupTagObject (HexColorSupportPatch)

- (CPColor)colorValueForAttribute:(CPString)attribute
{
    var value = [_attributes objectForKey:attribute];
    if (value == nil)
        return nil;

    var clean = value;
    if ([clean hasPrefix:@"#"])
        clean = [clean substringFromIndex:1];

    var sel = CPSelectorFromString(clean + "Color");
    if (sel && [CPColor respondsToSelector:sel])
        return [CPColor performSelector:sel];

    if (clean.length === 3)
    {
        var r = clean.charAt(0), g = clean.charAt(1), b = clean.charAt(2);
        clean = r + r + g + g + b + b;
    }

    if (clean.length === 6 || clean.length === 8)
    {
        var r = parseInt(clean.substring(0, 2), 16) / 255.0;
        var g = parseInt(clean.substring(2, 4), 16) / 255.0;
        var b = parseInt(clean.substring(4, 6), 16) / 255.0;
        var a = (clean.length === 8) ? (parseInt(clean.substring(6, 8), 16) / 255.0) : 1.0;

        if (!isNaN(r) && !isNaN(g) && !isNaN(b))
            return [CPColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    }

    return nil;
}

@end
