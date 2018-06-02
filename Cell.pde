// Michael Wulber
// 6/1/18

class Cell {
  public NPolygon poly;
  
  private color insideColor;
  private color wallColor;
  private float wallThickness;
  
  private float maxRadius;
  private float[] radii;
  private float[] theta;
  
  private float maxSpread;
  private float[] spread;
  private float[] phi;
  
  private PVector center;
  
  private PVector[] coreControls;
  private PVector[] coreMids;
  private PVector[] coreAnchors;  
  
  private PVector[] wallControls;
  private PVector[] wallMids;
  private PVector[] wallAnchors;
  
  Cell(NPolygon poly, color col) {
    this.poly = poly;
    
    this.insideColor = col;
    this.wallColor = color(0);
    this.wallThickness = 10.0;
    
    this.maxRadius = 0.95;
    this.maxSpread = 0.5;
    
    this.radii = new float[poly.vertices.length];
    this.theta = new float[poly.vertices.length];
    this.spread = new float[poly.vertices.length];
    this.phi = new float[poly.vertices.length];
    
    for (int i = 0; i < poly.vertices.length; ++i) {
      this.radii[i] = 0.1;
      this.theta[i] = 0.01;
      this.spread[i] = 0.0;
      this.phi[i] = 0.007;
    }
   
    this.center = calcCenter();
    
    this.coreControls = new PVector[poly.vertices.length];;
    this.coreMids = new PVector[poly.vertices.length];
    this.coreAnchors = new PVector[coreControls.length*2];
    
    this.wallControls = calcWallControls();
    this.wallMids = calcWallMids();
    this.wallAnchors = calcWallAnchors();
  }
  
  // renders a filled cell
  public void render() {
    renderCore();
    renderWall();
  }
  
  // renders the core of the cell
  private void renderCore() {
    // calculate control points
    for (int i = 0; i < coreControls.length; ++i) {
      coreControls[i] = weightedAverage(poly.vertices[i], center, radii[i]);
    }
    
    // calculate midpoints
    for (int i = 0; i < coreMids.length - 1; ++i) {
      coreMids[i] = weightedAverage(coreControls[i], coreControls[i + 1], 0.5f);
    }
    coreMids[coreMids.length - 1] = weightedAverage(coreControls[coreMids.length - 1], coreControls[0], 0.5f);
    
    // calculate anchorpoints
    PVector[] coreAnchors = new PVector[coreControls.length*2];
    for (int i = 0; i < coreControls.length; ++i) {
      coreAnchors[i * 2] = weightedAverage(coreControls[i], coreMids[i], spread[i]);
      coreAnchors[i * 2 + 1] = weightedAverage(coreControls[(i + 1)%poly.vertices.length], coreMids[i], spread[i]);
    }
    
    // fill draw calls
    fill(insideColor);
    noStroke();
    
    beginShape();
    vertex(coreAnchors[coreAnchors.length - 1].x, coreAnchors[coreAnchors.length - 1].y);
    for (int i = 0; i < coreControls.length; ++i) {
      quadraticVertex(coreControls[i].x, coreControls[i].y, coreAnchors[2*i].x, coreAnchors[2*i].y);
      quadraticVertex(coreMids[i].x, coreMids[i].y, coreAnchors[2*i + 1].x, coreAnchors[2*i + 1].y);
    }
    endShape(CLOSE);
  }
  
  // renders the wall of the cell
  private void renderWall() {
    // Draw Cell Wall
    noFill();
    stroke(wallColor);
    strokeWeight(wallThickness);
    
    beginShape();
    vertex(wallAnchors[wallAnchors.length - 1].x, wallAnchors[wallAnchors.length - 1].y);
    for (int i = 0; i < wallControls.length; ++i) {
      quadraticVertex(wallControls[i].x, wallControls[i].y, wallAnchors[2*i].x, wallAnchors[2*i].y);
      quadraticVertex(wallMids[i].x, wallMids[i].y, wallAnchors[2*i + 1].x, wallAnchors[2*i + 1].y);
    }
    endShape(CLOSE);
  }
  
  // redistributes the radial growth and spread values so that the cell grows in the direction of the point
  public void directGrowth(PVector point) {
    if (this.poly.contains(point)) {
      // calculate areas using shoelace formula
      float total_area = calcArea(wallControls);
      
      float[] areas = new float[wallControls.length];
      areas[0] = calcArea(wallControls[0], wallMids[0], point, wallMids[wallMids.length - 1]);
      for (int i = 1; i < wallControls.length; ++i) {
        areas[i] = calcArea(wallControls[i], wallMids[i], point, wallMids[i - 1]);
      }
      
      float total_theta = 0.0;
      float total_phi = 0.0;
      for (int i = 0; i < theta.length; ++i) {
        total_theta += theta[i];
        total_phi += phi[i];
      }
      
      for (int i = 0; i < theta.length; ++i) {
        theta[i] = (areas[(i + theta.length/2)%theta.length]/total_area) * total_theta;
        phi[i] = (areas[(i + phi.length/2)%phi.length]/total_area) * total_phi;
      }
    } else {
      // equally redistribute the growth
      float total_theta = 0.0;
      float total_phi = 0.0;
      for (int i = 0; i < theta.length; ++i) {
        total_theta += theta[i];
        total_phi += phi[i];
      }
      
      for (int i = 0; i < theta.length; ++i) {
        theta[i] = total_theta/theta.length;
        phi[i] = total_phi/phi.length;
      }
    }
  }
  
  // increments radii and spread of the core of the cell
  public void grow() {
    for (int i = 0; i < radii.length; ++i) {
      radii[i] += (maxRadius - radii[i]) * theta[i];
    }
    
    for (int i = 0; i < spread.length; ++i) {
      spread[i] += (maxSpread - spread[i]) * phi[i];
    }
  }
  
  // calculates a weighted average of two points
  public PVector weightedAverage(PVector A, PVector B, float weight) {
    return new PVector( weight * A.x + (1.0f - weight) * B.x, weight * A.y + (1.0f - weight) * B.y );
  }
  
  // calculates center of the cell
  private PVector calcCenter() {
    // calculate center
    float xx = 0.0f;
    float yy = 0.0f;
    for (int i = 0; i < poly.vertices.length; ++i) {
      xx += poly.vertices[i].x;
      yy += poly.vertices[i].y;
    }
    return new PVector(xx/poly.vertices.length, yy/poly.vertices.length);
  }
  
  // calculates control points of the bezier curves that define the cell wall
  private PVector[] calcWallControls() {
    PVector[] controlPoints = new PVector[poly.vertices.length];
    for (int i = 0; i < controlPoints.length; ++i) {
      controlPoints[i] = poly.vertices[i];
    }
    return controlPoints;
  }
  
  // calculates midpoints of the control points 
  private PVector[] calcWallMids() {
    PVector[] points = new PVector[poly.vertices.length];
    for (int i = 0; i < points.length - 1; ++i) {
      points[i] = weightedAverage(wallControls[i], wallControls[i + 1], 0.5f);
    }
    points[points.length - 1] = weightedAverage(wallControls[wallControls.length - 1], wallControls[0], 0.5f);
    return points;
  }
  
  // calculates anchor points of the bezier curves that define the cell wall
  private PVector[] calcWallAnchors() {
    PVector[] anchorPoints = new PVector[wallControls.length*2];
    for (int i = 0; i < wallControls.length; ++i) {
      anchorPoints[i * 2] = weightedAverage(wallControls[i], wallMids[i], maxSpread);
      anchorPoints[i * 2 + 1] = weightedAverage(wallControls[(i + 1)%poly.vertices.length], wallMids[i], maxSpread);
    }
    return anchorPoints;
  }
  
  // calculate area of a polygon using the shoelace formula
  private float calcArea(PVector... points) {
    float area = 0; //<>//
    for (int i = 0; i < points.length - 1; ++i) {
      area += points[i].x * points[i + 1].y - points[i + 1].x * points[i].y;
    }
    area += points[points.length - 1].x * points[0].y - points[0].x * points[points.length - 1].y;
    return 0.5 * abs(area);
  }
  
  public boolean shouldSplit() {
    return (calcArea(coreControls)/calcArea(wallControls) > 0.85);
  }
  
  // split cell into two fairly equal size cells
  public Cell[] split() {
    NPolygon[] polygons = poly.split();
    return new Cell[] {new Cell(polygons[0], color(92, 240, 255)), new Cell(polygons[1], color(92, 240, 255))};
  }
}