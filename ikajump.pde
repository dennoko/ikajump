int fps = 60;
boolean[] keys = new boolean[128];
String scene = "game";
int ballSize = 40;
int blockSize = 20;
int boxHeight = 400;
int boxNum = 5;
int totalHeight = boxHeight * boxNum;
float baseY = totalHeight - boxHeight;


void keyPressed() {
    if (key < 128) {
        keys[key] = true;
    }
    if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT || keyCode == 32) {
        keys[keyCode] = true;
    }
}

void keyReleased() {
    if (key < 128) {
        keys[key] = false;
    }
    if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT || keyCode == 32) {
        keys[keyCode] = false;
    }
}

class Player {
    float x, y;
    float px, py;
    float vx = 0, vy = 0;
    float maxVelocity = 5;
    float gravity = 0.5;
    int size =  ballSize;
    int radius = size / 2;
    int chargeFrame = 0;
    float maxJump = -20;

    Player(float x, float y) {
        this.x = x;
        this.y = y;
        this.px = this.x;
        this.py = this.y;
    }

    void move(int right) {
        if (right == 0) {
            vx = 0;
            return;
        }
        if (vy != 0) {
            vx += maxVelocity * right;
        }
    }

    void chargeJump() {
        if (chargeFrame < (fps/2)) {
            chargeFrame++;
        }
    }

    void jump() {
        if (chargeFrame != 0) {
            vy = maxJump * ((float)chargeFrame / (fps/2));
            chargeFrame = 0;
        }
    }

    void update() {
        vy += gravity;
        if (vy > 0) {
            vy = min(vy, maxVelocity*8);
        } else {
            vy = max(vy, -maxVelocity*8);
        }
        px = x;
        py = y;
        y += vy;
        x += vx;
        if (x < 0) {
            x = width;            
        } else if (x > width) {
            x = 0;
        }
        if (y > totalHeight - radius) {
            y = totalHeight - radius;
            vy = 0;
        }
        
        if (y < height/2) {
            baseY = 0;
        } else if (y > totalHeight - height/2) {
            baseY = totalHeight - height;
        } else {
            baseY = y - height / 2;
        }
    }

    void display() {
        float drawY = y - baseY;
        if (-height/2 < drawY && drawY < height*3/2) {
            // fill(255);
            fill(map(chargeFrame, 0, 60, 128, 255), 0, 0);
            ellipse(x, drawY, size, size);
        }
    }
}

abstract class Item {
    boolean exists = true;
    float x, y;
    int size = ballSize;
    int radius = size / 2;

    Item(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void collision(Player player) {
        if (exists && dist(player.x, player.y, x, y) < player.radius + radius) {
            exists = false;
            event(player);
        }
    }
    abstract void event(Player player);

    abstract void display();
}

class GoalItem extends Item {
    GoalItem(float x, float y) {
        super(x, y);
    }

    void event(Player player) {
        scene = "goal";
    }

    void display() {
        if (exists) {
            float drawY = y - baseY;
            if (-height/2 < drawY && drawY < height*3/2) {
                fill(255, 255, 0);
                ellipse(x, drawY, size, size);
            }
        }
    }
}

class BoostItem extends Item {
    BoostItem(float x, float y) {
        super(x, y);
    }

    void event(Player player) {
        player.vy = player.maxJump;
    }
    
    void display() {
        if (exists) {
            float drawY = y - baseY;
            if (-height/2 < drawY && drawY < height*3/2) {
                fill(0, 255, 0);
                ellipse(x, drawY, size, size);
            }
        }
    }
}

class Star {
    float x, y, size;

    Star() {
        x = random(width);
        y = random(boxHeight);
        size = random(1, 3);
    }
    
    void display(float addY) {
        float drawY = y - baseY + addY;
        if (-height/2 < drawY && drawY < height*3/2) {
            fill(255);
            ellipse(x, drawY, size, size);
        }
    }
}

class Platform {
    float x, y, w, vx;
    color c;
    Platform(float x, float y, int w) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.vx = 0;
        this.c = color(127, 63, 0);
    }

    void collision(Player player) {
        if ((player.py + player.radius <= y && player.y + player.radius > y) && ((player.x + player.radius > x && player.x - player.radius < x + blockSize*w) || (player.x + player.radius > x - width && player.x - player.radius < x + blockSize*w - width))) {
            player.y = y - player.radius;
            player.vy = 0;
            player.x += this.vx;
        }
    }

    void display() {
        float drawY = y - baseY;
        float endX = x + blockSize*w;
        if (-height/2 < drawY && drawY < height*3/2) {
            fill(c);
            rect(x, drawY, blockSize*w, blockSize);
            if (endX > width) {
                rect(x - width, drawY, blockSize*w, blockSize);
            }
        }
    }
}

class MovePlatform extends Platform {
    float x0, rangeX;
    MovePlatform(float x, float y, int w, float vx, float rangeX) {
        super(x, y, w);
        this.x0 = x;
        this.vx = vx;
        this.rangeX = rangeX;
        this.c = color(127, 127, 255);
    }

    void update() {
        x += vx;
        if (x < x0 - rangeX) {
            x = x0 - rangeX;
            vx = -vx;
        } else if (x > x0 + rangeX) {
            x = x0 + rangeX;
            vx = -vx;
        }
        if (x < 0) {
            x = width;
        } else if (x > width) {
            x = 0;
        }
    }
}



Player player;
GoalItem goal;
ArrayList<Star> stars = new ArrayList<Star>();
ArrayList<BoostItem> boostItems = new ArrayList<BoostItem>();
ArrayList<Platform> platforms = new ArrayList<Platform>();
ArrayList<MovePlatform> movePlatforms = new ArrayList<MovePlatform>();

void setup() {
    size(800, 600);
    frameRate(fps);
    background(0);
    noStroke();
    
    player = new Player(width/2, totalHeight - blockSize - ballSize/2);
    goal = new GoalItem(width/2, 150);
    for (int i = 0; i < 8; ++i) {
        stars.add(new Star());
    }
    boostItems.add(new BoostItem(random(width), 600));
    boostItems.add(new BoostItem(random(width), 1000));
    boostItems.add(new BoostItem(random(width), 1400));
    boostItems.add(new BoostItem(random(width), 1800));
    platforms.add(new Platform(0, totalHeight - blockSize, width/blockSize));
    platforms.add(new Platform(100, totalHeight - boxHeight, 10));
    platforms.add(new Platform(400, totalHeight - boxHeight*2, 5));
    platforms.add(new Platform(700, totalHeight - boxHeight*4, 15));
    movePlatforms.add(new MovePlatform(200, totalHeight - boxHeight*3, 5, 1, 100));
}



boolean wasSpaceKeyPressed = false;
void draw() {
    background(0);
    for (Star star : stars) {
        for (int i = 0; i < boxNum; i++) {
            star.display(i*boxHeight);
        }
    }
    
    if (scene == "game") {
        player.move(0);
        if (keys['A'] || keys['a'] || keys[LEFT]) {
            player.move(-1);
        }
        if (keys['D'] || keys['d'] || keys[RIGHT]) {
            player.move(1);
        }
        if (keys[' '] || keys[32]) {
            wasSpaceKeyPressed = true;
            player.chargeJump();
        } else if (wasSpaceKeyPressed) {
            player.jump();
            wasSpaceKeyPressed = false;
        }
        player.update();
    }

    goal.collision(player);
    goal.display();
    for (BoostItem boostItem : boostItems) {
        boostItem.collision(player);
        boostItem.display();
    }
    for (Platform platform : platforms) {
        platform.collision(player);
        platform.display();
    }
    for (MovePlatform movePlatform : movePlatforms) {
        movePlatform.update();
        movePlatform.collision(player);
        movePlatform.display();
    }
    player.display();

    if (scene == "goal") {
        fill(255);
        textSize(50);
        text("Goal!", width/2 - 50, height/2);
    }
}
