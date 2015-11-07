# SmoothScribble
#### Smooth Drawing for iOS in Swift with Hermite Spline Interpolation

##### _Companion project to this blog post: http://flexmonkey.blogspot.co.uk/2015/11/smooth-drawing-for-ios-in-swift-with.html_

If you’re creating a drawing or painting app for iOS, you may recall from my recent post discussing coalesced touches a way to increase touch resolution and access intermediate touch locations that may have occurred between touchesMoved invocations. However, if your app simply draws straight lines between each touch location, even the coalesced ones, and your user moves their finger or Pencil quickly, they’ll see their drawing rendered as line sections.

There’s a better solution: using a spline interpolation to draw Bezier curves between each touch location and render out a single, continuous curve. I’ve discussed spline interpolation in the past when drawing a curve to pass through all the control points of a Core Image Tone Curve filter and this project borrows that code but repurposes it for a drawing application:.

My demo app presents the user with two boxes into either of which they can scribble a drawing, which is mirrored in the other box. The box on the left renders their drawing using spline interpolation and the box on the right with straight lines for touch location to touch location (albeit with coalesced touched). It’s immediately obvious how much nicer the drawing on the left is, appearing as a single curve.

## SmoothScribble Basics

Both of the boxes on the screen are sub-classed `ScribbleView` instances which conform to `Scribblable`. The `ScribbleView` class is simply a `UIView` which contains two additional `CAShapeLayer` - `backgroundLayer` for displaying “historical” scribbles and a "working" drawingLayer for displaying the current, in progress scribble. 

The `Scribblable` protocol contains three methods invoked at the beginning, during and at the end of a scribble gesture and a method to clear it.

    func beginScribble(point: CGPoint)
    func appendScribble(point: CGPoint)
    func endScribble()
    func clearScribble()

## `SimpleScribbleView` Class 

Let’s look at the simple implementation first. `SimpleScribbleView` will draw straight lines starting at the point set by `beginScribble()`:

    let simplePath = UIBezierPath()
    
    func beginScribble(point: CGPoint)
    {
        simplePath.moveToPoint(point)
    }

Then adding lines to its `simplePath` and updating the drawing layer’s path with each move:

    func appendScribble(point: CGPoint)
    {
        simplePath.addLineToPoint(point)
        
        drawingLayer.path = simplePath.CGPath
    }

Finally, when the user lifts their finger from the screen, the `simplePath` is appended to any existing background path (the “historical” scribbles) and then cleared:

    func endScribble()
    {
        if let backgroundPath = backgroundLayer.path
        {
            simplePath.appendPath(UIBezierPath(CGPath: backgroundPath))
        }
        
        backgroundLayer.path = simplePath.CGPath
        
        simplePath.removeAllPoints()
        
        drawingLayer.path = simplePath.CGPath
    }

The result is, as you can see above, a series of straight lines with the line artefacts looking worse the faster the user moves their finger.

## `HermiteScribbleView` Class

The spline interpolated version is a little different. Here, in addition to a `UIBezierPath` to hold the current scribble, there’s also an array of all the points that the path consists of and it will need to interpolate: 

    let hermitePath = UIBezierPath()
    var interpolationPoints = [CGPoint]()

When `beginScribble()` is invoked on `HermiteScribbleView`, it creates a new array of those interpolation points and populates it with the initial position:

    func beginScribble(point: CGPoint)
    {
        interpolationPoints = [point]
    }

Now with each move, it appends the new point to the interpolationPoints array and uses an extension I wrote to `UIBezierPath` named `interpolatePointsWithHermite()` to build a series of Bezier curves to give that smooth Hermite interpolated splines between all the points:

    func appendScribble(point: CGPoint)
    {
        interpolationPoints.append(point)
        
        hermitePath.removeAllPoints()
        hermitePath.interpolatePointsWithHermite(interpolationPoints)
        
        drawingLayer.path = hermitePath.CGPath
    }

Finally, the `endScribble()` of `HermiteScribbleView` does pretty much the same thing as its simpler sibling, appending a copy of its “working” layer to its “historical” layer:

    func endScribble()
    {
        if let backgroundPath = backgroundLayer.path
        {
            hermitePath.appendPath(UIBezierPath(CGPath: backgroundPath))
        }
        
        backgroundLayer.path = hermitePath.CGPath
        
        hermitePath.removeAllPoints()
        
        drawingLayer.path = hermitePath.CGPath
    }

## Wiring up `SimpleScribbleView` and `HermiteScribbleView`

The main view controller uses a `UIStackView` to position the two scribble views either side-by-side in landscape of above and below each other in portrait.  

In touches began, I figure out which of the two views is the source and set that to `touchOrigin`: 

    if(hermiteScribbleView.frame.contains(location))
    {
       touchOrigin = hermiteScribbleView
    }
    else if (simpleScribbleView.frame.contains(location))
    {
        touchOrigin = simpleScribbleView
    }
    else
    {
        touchOrigin = nil
        return
    }

With that set, I can use the touch’s `locationInView` for `touchOrigin` to apply the same touch information to both views.

You may have already guessed that it’s also the view controller’s `touchesBegan()` that invokes `beginScribble()`:

    if let adjustedLocationInView = touches.first?.locationInView(touchOrigin)
    {
        hermiteScribbleView.beginScribble(adjustedLocationInView)
        simpleScribbleView.beginScribble(adjustedLocationInView)
    }

The `appendScribble()` is invoked inside the view controller’s `touchesMoved()`:

    coalescedTouches.forEach
    {
        hermiteScribbleView.appendScribble($0.locationInView(touchOrigin))
        simpleScribbleView.appendScribble($0.locationInView(touchOrigin))
    }

Which just leaves `touchesEnded()` to invoke `endScribble()`:

    hermiteScribbleView.endScribble()
    simpleScribbleView.endScribble()

## In Conclusion

No matter how fast your code is, there’s a good chance your user’s fingers are faster. If you have a drawing app, smoothly interpolating a user’s gesture rather than just drawing straight lines between each touch location makes their drawings look far more natural and, maybe, closer to the image they had in mind.

As always, the source code to this little demo app is available at my GitHub repository here. Enjoy!
