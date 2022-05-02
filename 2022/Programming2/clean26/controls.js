class HandlerInterface
{
  onKeyLeft(b) {}
  onKeyRight(b) {}
  onKeyFire(b) {}
  onMouse(pt) {}
}

class Controls
{
  constructor(element, handler)
  {
    this.handler = handler;
    this.element = element;
    this.attachKeys();
    this.attachMouse();
  }

  attachKeys()
  {
    var leftKey = 37, upKey = 38, rightKey = 39, downKey = 40, spaceKey = 32;
    this.keystate = {};
    document.addEventListener("keydown", e => {
      switch (e.keyCode)
      {
        case leftKey: this.handler.onKeyLeft(true); break;
        case rightKey: this.handler.onKeyRight(true); break;
        case spaceKey: this.handler.onKeyFire(true); break;
      }
    });
    document.addEventListener("keyup", e => {
      switch (e.keyCode)
      {
        case leftKey: this.handler.onKeyLeft(false); break;
        case rightKey: this.handler.onKeyRight(false); break;
        case spaceKey: this.handler.onKeyFire(false); break;
      }
    });
  }

  mousePress(p) {
   this.handler.onMouse(p);
  }
  mouseRelease(p) {}
  mouseMove(p) {}

  attachMouse()
  {
	// Set up mouse events for drawing
	this.element.addEventListener("mousedown", (e) => {
	        this.mousePress(getMousePos(this.element, e));
	}, false);
	this.element.addEventListener("mouseup", (e) => {
	        this.mouseRelease(getMousePos(this.element, e));
	}, false);
	this.element.addEventListener("mousemove", e => {
	        this.mouseMove(getMousePos(this.element, e));
	}, false);

	// Set up touch events for mobile, etc
	this.element.addEventListener("touchstart", function (e) {
		mousePos = getTouchPos(canvas, e);
		var touch = e.touches[0];
		var mouseEvent = new MouseEvent("mousedown", {
			clientX: touch.clientX,
			clientY: touch.clientY
		});
		this.element.dispatchEvent(mouseEvent);
                e.preventDefault(); 
	}, false);
	this.element.addEventListener("touchend", function (e) {
		var mouseEvent = new MouseEvent("mouseup", {});
		this.element.dispatchEvent(mouseEvent);
                e.preventDefault(); 
	}, false);
	this.element.addEventListener("touchmove", function (e) {
		var touch = e.touches[0];
		var mouseEvent = new MouseEvent("mousemove", {
			clientX: touch.clientX,
			clientY: touch.clientY
		});
		this.element.dispatchEvent(mouseEvent);
                e.preventDefault(); 
	}, false);

	// Prevent scrolling when touching the canvas
	document.body.addEventListener("touchstart", function (e) {
		if (e.target == this.element) {
			e.preventDefault();
		}
	}, false);
	document.body.addEventListener("touchend", function (e) {
		if (e.target == this.element) {
			e.preventDefault();
		}
	}, false);
	document.body.addEventListener("touchmove", function (e) {
		if (e.target == this.element) {
			e.preventDefault();
		}
	}, false);

	// Get the position of the mouse relative to the canvas
	var getMousePos = (canvasDom, mouseEvent) => {
		var rect = canvasDom.getBoundingClientRect();
                var kx = canvasDom.clientWidth/parseInt(canvasDom.style.width);
                var ky = canvasDom.clientHeight/parseInt(canvasDom.style.height);
		return {
			x: (mouseEvent.clientX - rect.left)/kx,
			y: (mouseEvent.clientY - rect.top)/ky
		};
	}

	// Get the position of a touch relative to the canvas
	var getTouchPos = (canvasDom, touchEvent) => {
		var rect = canvasDom.getBoundingClientRect();
                var kx = canvasDom.clientWidth/parseInt(canvasDom.style.width);
                var ky = canvasDom.clientHeight/parseInt(canvasDom.style.height);
		return {
			x: (touchEvent.touches[0].clientX - rect.left)/kx,
			y: (touchEvent.touches[0].clientY - rect.top)/ky
		};
	}
  }
}
