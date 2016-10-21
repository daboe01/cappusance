/* -*-objc-*-


   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: January 2003
   Author of Cappuccino port: Daniel Boehringer (2012)

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

@import "GSMarkupTagObject.j"

@implementation GSMarkupTagTableColumn: GSMarkupTagObject

+ (CPString) tagName
{
  return @"tableColumn";
}

+ (Class) platformObjectClass
{
  return [FSTableColumn class];
}

- (id) initPlatformObject: (id)platformObject
{
  /* identifier */
  {
    var identifier = [_attributes objectForKey: @"identifier"];

    if (identifier != nil)
      {
	platformObject = [platformObject initWithIdentifier: identifier];
      }  
    else
      {
	/* FIXME: truly, this is invalid ... identifier *must* be
	 * there.  */
	platformObject = [platformObject init];
      }
  }
  
  /* editable */
  {
    var editable = [self boolValueForAttribute: @"editable"];
    
    if (editable == 1)
      {
	[platformObject setEditable: YES];
      }
    else if (editable == 0)
      {
	[platformObject setEditable: NO];
      }
  }

  /* title */
  {
    var title = [self localizedStringValueForAttribute: @"title"];
    if (title != nil)
      {
	[[platformObject headerView] setStringValue: title];
      }
  }

  /* minWidth */
  {
    var aValue = [_attributes objectForKey: @"minWidth"];
    
    if (aValue != nil)
      {
	[platformObject setMinWidth: [aValue intValue]];
      }
  }

  /* maxWidth */
  {
    var aValue = [_attributes objectForKey: @"maxWidth"];
    
    if (aValue != nil)
      {
	[platformObject setMaxWidth: [aValue intValue]];
      }
  }

  /* width */
  {
    var aValue = [_attributes objectForKey: @"width"];
    
    if (aValue != nil)
      {
	[platformObject setWidth: [aValue intValue]];
      }
  }
  
  /* resizable */
  {
    var resizable = [self boolValueForAttribute: @"resizable"];
    if (resizable == 1)
      {
	[platformObject setResizable: YES];	
      }
    else if (resizable == 0)
      {
	[platformObject setResizable: NO];
      }
  }
  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end

@implementation FSTableColumn:CPTableColumn
-(void) setDataView:(CPView) aView
{
    [super setDataView:aView];
    [_tableView _reloadDataViews];
}

- (void)_prepareDataView:(CPView)aDataView forRow:(unsigned)aRow
{
    var bindingsDictionary = [CPBinder allBindingsForObject:self],
        keys = [bindingsDictionary allKeys];

    for (var i = 0, count = [keys count]; i < count; i++)
    {
        var bindingName = keys[i],
            bindingPath = [aDataView _replacementKeyPathForBinding:bindingName],
            binding = [bindingsDictionary objectForKey:bindingName],
            bindingInfo = binding._info,
            destination = [bindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [bindingInfo objectForKey:CPObservedKeyPathKey],
            dotIndex = keyPath.lastIndexOf("."),
            value;

        if (dotIndex === CPNotFound)
        {
            value = [[destination valueForKeyPath:keyPath] objectAtIndex:aRow];
        }
        else
        {
            /*
                Optimize the prototypical use case where the key path describes a value
                in an array. Without this optimization, we call CPArray's valueForKey
                which generates as many values as objects in the array, of which we then
                pick one and throw away the rest.

                The optimization is to get the array and access the value directly. This
                turns the operation into a single access regardless of how long the model
                array is.
            */

            var firstPart = keyPath.substring(0, dotIndex),
                secondPart = keyPath.substring(dotIndex + 1),
                firstValue = [destination valueForKeyPath:firstPart];

            if ([firstValue isKindOfClass:CPArray])
            {
                if (aRow < [firstValue count])
                    value = [[firstValue objectAtIndex:aRow] valueForKeyPath:secondPart];
            }
            else
            {
                value = [[firstValue valueForKeyPath:secondPart] objectAtIndex:aRow];
            }  
        }

        value = [binding transformValue:value withOptions:[bindingInfo objectForKey:CPOptionsKey]];
        if([aDataView isKindOfClass:CPPopUpButton])
        {   [aDataView setSelectedTag:value];
        }
        else
            [aDataView setObjectValue:value];
    }
}

/*!
    @ignore
*/

- (void)_reverseSetDataView:(CPView)aDataView forRow:(unsigned)aRow
{
    var bindingsDictionary = [CPBinder allBindingsForObject:self],
        keys = [bindingsDictionary allKeys],
        newValue = [aDataView valueForKey: [aDataView isKindOfClass: [CPPopUpButton class] ] ? @"selectedTag":@"objectValue"];

    for (var i = 0, count = [keys count]; i < count; i++)
    {
        var bindingName = keys[i],
            bindingPath = [aDataView _replacementKeyPathForBinding:bindingName],
            binding = [bindingsDictionary objectForKey:bindingName],
            bindingInfo = binding._info,
            destination = [bindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [bindingInfo objectForKey:CPObservedKeyPathKey],
            options = [bindingInfo objectForKey:CPOptionsKey],
            dotIndex = keyPath.lastIndexOf(".");

        newValue = [binding reverseTransformValue:newValue withOptions:options];

        if (dotIndex === CPNotFound)
            [[destination valueForKeyPath:keyPath] replaceObjectAtIndex:aRow withObject:newValue];
        else
        {
            var firstPart = keyPath.substring(0, dotIndex),
                secondPart = keyPath.substring(dotIndex + 1),
                firstValue = [destination valueForKeyPath:firstPart];

            if ([firstValue isKindOfClass:CPArray])
            {   var target = [firstValue objectAtIndex:aRow];
                var oldValue = [target valueForKeyPath:secondPart];

                if(oldValue !== newValue)
                {
                     var ac = [binding._info objectForKey:CPObservedObjectKey]; // important for undo support
                     [ac setValue:newValue target:target forKeyPath:secondPart oldValue:oldValue];
                }
           }
           else [[firstValue valueForKeyPath:secondPart] replaceObjectAtIndex:aRow withObject:newValue];
        }
    }
}
@end
