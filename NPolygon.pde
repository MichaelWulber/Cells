// Michael Wulber
// 6/1/18
// N-gon + Triangulation
// Uses: custom fitting, efficient collision regions 

import java.util.LinkedList;

class NPolygon {
  // assumes:
  // (1) vertices are in clockwise order 
  // (2) the first and last vertices form an edge
  // (3) the polygon is convex 
  // eventually I want to handle both convex and concave polygons but that makes triangulation non-trivial
  
  public PVector[]  vertices; 
  public int[] triangles;
  
  NPolygon(PVector[]  vertices, int[] triangles) {
    this.vertices = vertices;
    this.triangles = triangles;
  }
  
  NPolygon(PVector[]  vertices) {
    this.vertices = vertices;
    this.triangles = triangulate(vertices);
  }
  
  // verifies if another polygon intersects this polygon
  public boolean intersects(NPolygon polygon) {
    boolean b1, b2, b3;
    for (int i = 0; i < triangles.length - 1; i += 3) {
      for (PVector point : polygon.vertices) {
        b1 = getSign(point, vertices[i], vertices[i + 1]) < 0;
        b2 = getSign(point, vertices[i + 1], vertices[i + 2]) < 0;
        b3 = getSign(point, vertices[i + 2], vertices[i]) < 0;
        
        if ( (b1 == b2) && (b2 == b3) ) return true;
      }
    }
    return false;
  }
  
  // verifies if a point is inside the polygon
  public boolean contains(PVector point) {
    boolean b1, b2, b3;
    for (int i = 0; i < triangles.length - 1; i += 3) {
      b1 = getSign(point, vertices[triangles[i]], vertices[triangles[i + 1]]) < 0;
      b2 = getSign(point, vertices[triangles[i + 1]], vertices[triangles[i + 2]]) < 0;
      b3 = getSign(point, vertices[triangles[i + 2]], vertices[triangles[i]]) < 0;
        
      if ( (b1 == b2) && (b2 == b3) ) return true;
    }
    return false;
  }
  
  // outline triangle regions of NPoly
  public void showOutline(float r, float g, float b) {
    stroke(color(r, g, b));
    strokeWeight(2);
    for (int i = 0; i < triangles.length - 1; i += 3) {
      line(vertices[triangles[i]].x, vertices[triangles[i]].y, vertices[triangles[i + 1]].x, vertices[triangles[i + 1]].y);
      line(vertices[triangles[i + 1]].x, vertices[triangles[i + 1]].y, vertices[triangles[i + 2]].x, vertices[triangles[i + 2]].y);
      line(vertices[triangles[i]].x, vertices[triangles[i]].y, vertices[triangles[i + 2]].x, vertices[triangles[i + 2]].y);
    }
  }

  // triangle intersection helper (checks whether p1 is in the half space determined by p2 and p3)
  private float getSign(PVector p1, PVector p2, PVector p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
  }
  
  // triangulates a concave polygon given vertices in clockwise order (fanning strategy)
  private int[] triangulate(PVector[] vertices) {
    int[] triangles = new int[3 * (vertices.length - 2)];
    
    for (int i = 0; i < vertices.length - 2 ; ++i) {
      triangles[i * 3] = 0;
      triangles[i * 3 + 1] = i + 1;
      triangles[i * 3 + 2] = i + 2;
    }
    return triangles;
  }
  
  public NPolygon[] split() {
    // calculate midpoints
    PVector[] midpoints = new PVector[vertices.length];
    for (int i = 0; i < vertices.length - 1; ++i) {
      midpoints[i] = weightedAverage(vertices[i], vertices[i + 1], 0.5);
    }
    midpoints[vertices.length - 1] = weightedAverage(vertices[vertices.length - 1], vertices[0], 0.5);
    
    // merge the vertices and midpoints v[0], m[0], ..., v[n-1], m[n-1]
    PVector[] pool = new PVector[vertices.length * 2];
    for (int i = 0; i < vertices.length; ++i) {
      pool[2 * i] = vertices[i];
      pool[2 * i + 1] = midpoints[i];
    }
    
    // select random vertex from the pool
    int indexA = int(random(pool.length));
    int indexB = (indexA + pool.length/2) % pool.length;
    
    // create new vertex lists
    LinkedList<PVector> vA = new LinkedList();
    LinkedList<PVector> vB = new LinkedList();
    
    vA.push(pool[indexA]);
    for (int i = (indexA + 1)%pool.length; i != indexB; i = (i+1)%pool.length) {
      if (i % 2 == 0) {
        vA.push(pool[i]);
      }
    }
    vA.push(pool[indexB]);
    
    vB.push(pool[indexB]);
    for (int i = (indexB + 1)%pool.length; i != indexA; i = (i+1)%pool.length) {
      if (i % 2 == 0) {
        vB.push(pool[i]);
      }
    }
    vB.push(pool[indexA]);
    
    return new NPolygon[]{new NPolygon(vA.toArray(new PVector[1])), new NPolygon(vB.toArray(new PVector[1]))};
  }
  
  // calculates a weighted average of two points
  public PVector weightedAverage(PVector A, PVector B, float weight) {
    return new PVector( weight * A.x + (1.0f - weight) * B.x, weight * A.y + (1.0f - weight) * B.y );
  }
}