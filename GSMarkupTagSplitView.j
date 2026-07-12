/*
 * GSMarkupTagSplitView.j with CPSplitView Monkeypatch
 *
 */

@import "GSMarkupTagView.j"

#pragma mark - CPSplitView Monkeypatch Category

var ShouldSuppressResizeNotifications   = 1,
    DidPostWillResizeNotification       = 2,
    DidSuppressResizeNotification       = 4;

@implementation CPSplitView (AutosaveFix)

- (void)setFrameSize:(CGSize)aSize
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize)
    {
        _shouldAutosave = NO;
    }

    [super setFrameSize:aSize];

    if (_shouldRestoreFromAutosaveUnlessFrameSize)
    {
        _shouldAutosave = YES;
    }
}

- (void)_autosave
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize || !_shouldAutosave || !_autosaveName)
    {
        return;
    }

    var userDefaults = [CPUserDefaults standardUserDefaults],
        autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]],
        count = [_arrangedSubviews count],
        positions = [CPMutableArray new],
        preCollapseArray = [CPMutableArray new];

    for (var i = 0; i < count; i++)
    {
        var frame = [_arrangedSubviews[i] frame];
        [positions addObject:CGStringFromRect(frame)];
        [preCollapseArray addObject:[_preCollapsePositions objectForKey:"" + i]];
    }

    [userDefaults setObject:positions forKey:autosaveName];
    [userDefaults setObject:preCollapseArray forKey:autosavePrecollapseName];
}

- (void)_restoreFromAutosave
{
    if (!_autosaveName)
    {
        return;
    }

    var autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]],
        userDefaults = [CPUserDefaults standardUserDefaults],
        frames = [userDefaults objectForKey:autosaveName],
        preCollapseArray = [userDefaults objectForKey:autosavePrecollapseName];

    if (frames)
    {
        var dividerThickness = [self dividerThickness],
            position = 0;

        _shouldAutosave = NO;

        var myOtherSize = [self frame].size[_otherSizeComponent];

        for (var i = 0, count = _arrangedSubviews.length, frame; i < count; i++)
        {
            frame = CGRectFromString(frames[i]);

            frame.size[_otherSizeComponent] = myOtherSize;

            [_arrangedSubviews[i] setFrame:frame];
        }

        for (var i = 0, count = _dividerSubviews.length, size; i < count; i++)
        {
            size = CGSizeMakeCopy([_dividerSubviews[i] frameSize]);

            size[_otherSizeComponent] = myOtherSize;

            [_dividerSubviews[i] setFrameSize:size];
        }

        _shouldAutosave = YES;
    }

    if (preCollapseArray)
    {
        _preCollapsePositions = [CPMutableDictionary new];

        for (var i = 0, count = [preCollapseArray count]; i < count; i++)
        {
            var item = preCollapseArray[i];

            if (item == nil)
                [_preCollapsePositions removeObjectForKey:String(i)];
            else
                [_preCollapsePositions setObject:item forKey:String(i)];
        }
    }
}

- (void)adjustSubviews
{
    if ((_suppressResizeNotificationsMask & DidPostWillResizeNotification) === 0)
    {
        [self _postNotificationWillResize];
        _suppressResizeNotificationsMask |= DidPostWillResizeNotification;
    }

    var sizeToFit   = [self frame].size[_sizeComponent] - _dividerSubviews.length * [self dividerThickness],
        fixedSize   = 0,
        nbSubviews  = _arrangedSubviews.length;

    for (var i = 0; i < nbSubviews; i++)
        if (!_isFlexible[i])
            fixedSize += [_arrangedSubviews[i] frameSize][_sizeComponent];

    if (fixedSize < sizeToFit)
    {
        var newFlexibleSize = sizeToFit - fixedSize,
            remainingSpace  = newFlexibleSize,
            flexibleCount   = 0;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
            if (_isFlexible[i])
            {
                flexibleCount++;
                size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);
                floatSize = MIN((newFlexibleSize * _ratios[i]), remainingSpace);
                cumulativeFloatSize += floatSize;

                intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
                cumulativeIntSize += intSize;

                remainingSpace -= size[_sizeComponent] = intSize;

                [_arrangedSubviews[i] setFrameSize:size];
            }

        if (remainingSpace > 0)
            [self _distribute:remainingSpace amoung:flexibleCount onFlexible:YES fromIndex:0 toIndex:nbSubviews-1];
    }
    else
    {
        var remainingSpace = sizeToFit,
            fixedCount     = 0;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
        {
            size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);

            if (_isFlexible[i])
                size[_sizeComponent] = 0;
            else
            {
                fixedCount++;
                floatSize = MIN((sizeToFit * _ratios[i]), remainingSpace);
                cumulativeFloatSize += floatSize;

                intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
                cumulativeIntSize += intSize;

                remainingSpace -= size[_sizeComponent] = intSize;
            }

            [_arrangedSubviews[i] setFrameSize:size];
        }

        if (remainingSpace > 0)
            [self _distribute:remainingSpace amoung:fixedCount onFlexible:NO fromIndex:0 toIndex:nbSubviews-1];
    }

    if ((_suppressResizeNotificationsMask & ShouldSuppressResizeNotifications) !== 0)
        _suppressResizeNotificationsMask |= DidSuppressResizeNotification;
    else
        [self _postNotificationDidResize];

    [self layoutSubviews];
}

@end


#pragma mark - GSMarkupTagSplitView Klasse

@implementation GSMarkupTagSplitView : GSMarkupTagView

+ (CPString)tagName
{
    return @"splitView";
}

+ (Class)platformObjectClass
{
    return [CPSplitView class];
}

- (id)initPlatformObject:(id)platformObject
{
    platformObject = [platformObject init];
    
    if ([self boolValueForAttribute:@"vertical"] == 0)
    {
        [platformObject setVertical:NO];
    }
    else
    {
        [platformObject setVertical:YES];
    }
    
    // Der autosaveName wird hier noch nicht auf das platformObject übertragen,
    // um ein Überschreiben der UserDefaults durch die initialen Layout-Zyklen zu verhindern.
    var autosaveName = [_attributes objectForKey:@"autosaveName"];
  
    var count = [_content count];
    for (var i = 0; i < count; i++)
    {
        var view = [_content objectAtIndex:i];
        var v = [view platformObject];
        if (v != nil && [v isKindOfClass:[CPView class]])
        {
            [platformObject addSubview:v];
        }
    }
    return platformObject;
}

- (void)_delayedRestoreFromAutosave:(id)platformObject
{
    var autosaveName = [_attributes objectForKey:@"autosaveName"];
    
    [platformObject setAutosaveName:autosaveName];
    [platformObject _restoreFromAutosave];
    
    if ([platformObject respondsToSelector:@selector(_updateRatios)])
    {
        [platformObject _updateRatios];
    }
    
    [platformObject adjustSubviews];
    
    var currentSize = [platformObject frameSize];
    platformObject._shouldRestoreFromAutosaveUnlessFrameSize = CGSizeMakeCopy(currentSize);
}

- (id)postInitPlatformObject:(id)platformObject
{
    platformObject = [super postInitPlatformObject:platformObject];

    var autosaveName = [_attributes objectForKey:@"autosaveName"];
    if (autosaveName)
    {
        [[CPRunLoop currentRunLoop] performSelector:@selector(_delayedRestoreFromAutosave:) 
                                             target:self 
                                           argument:platformObject 
                                              order:0 
                                              modes:[CPDefaultRunLoopMode]];
    }
    else
    {
        [platformObject adjustSubviews];
    }

    return platformObject;
}

@end
