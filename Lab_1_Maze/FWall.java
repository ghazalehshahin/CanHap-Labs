import co.haply.hphysics.*;

public class FWall extends FBox {
    public boolean bumped = false;

    protected float m_x;
    protected float m_y;
    protected float m_width;
    protected float m_height;

    public FWall(float x, float y, float width, float height) {
        super(width, height);
        
        m_x = x;
        m_y = y;
        m_width = width;
        m_height = height;

        this.setFill(0);
        this.setNoStroke();
        this.setStaticBody(true);
        this.setPosition(m_x + width/2, m_y + height/2);
        setBumpedState(false);
    }

    public boolean getBumpedState(){
        return bumped;
    }

    public void setBumpedState(boolean newState){
        bumped = newState;
    }
}
