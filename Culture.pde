// Michael Wulber
// 6/1/2018

import java.util.LinkedList;

class Culture {
  public LinkedList<Cell> cells;
  
  Culture(Cell... cells) {
    this.cells = new LinkedList<Cell>();
    for (int i = 0; i < cells.length; ++i) {
      this.cells.push(cells[i]);
    }
  }
  
  public void grow() { //<>//
    LinkedList<Cell> removeCells = new LinkedList();
    LinkedList<Cell> addCells = new LinkedList();
    
    for (Cell c : cells) {
      //c.directGrowth(new PVector(mouseX, mouseY));
      c.grow();
      if (c.shouldSplit()) {
        Cell[] children = c.split();
        addCells.add(children[0]);
        addCells.add(children[1]);
        removeCells.add(c);
      }
    }
    
    for (Cell c : removeCells) {
      cells.remove(c);
    }
    
    for (Cell c : addCells) {
      cells.add(c);
    }
  }
  
  public void render() {
    for (Cell c: cells) {
      c.render();
    }
  }
  
  
}