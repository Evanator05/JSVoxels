class Vector3 {
    constructor(x, y, z) {
      this.x = x;
      this.y = y;
      this.z = z;
    }
  
    // Method to rotate the vector around the X axis
    rotateX(angle) {
      const rad = angle * Math.PI / 180;
      const cos = Math.cos(rad);
      const sin = Math.sin(rad);
      const newY = this.y * cos - this.z * sin;
      const newZ = this.y * sin + this.z * cos;
      return new Vector3(this.x, newY, newZ);
    }
  
    // Method to rotate the vector around the Y axis
    rotateY(angle) {
      const rad = angle * Math.PI / 180;
      const cos = Math.cos(rad);
      const sin = Math.sin(rad);
      const newX = this.x * cos + this.z * sin;
      const newZ = -this.x * sin + this.z * cos;
      return new Vector3(newX, this.y, newZ);
    }
  
    // Method to rotate the vector around the Z axis
    rotateZ(angle) {
      const rad = angle * Math.PI / 180;
      const cos = Math.cos(rad);
      const sin = Math.sin(rad);
      const newX = this.x * cos - this.y * sin;
      const newY = this.x * sin + this.y * cos;
      return new Vector3(newX, newY, this.z);
    }
  
    // Method to get the length of the vector
    length() {
      return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }
  
    // Method to normalize the vector
    normalize() {
      const len = this.length();
      return new Vector3(this.x / len, this.y / len, this.z / len);
    }
  
    // Method to calculate the dot product of two vectors
    dot(other) {
      return this.x * other.x + this.y * other.y + this.z * other.z;
    }
  
    // Method to calculate the cross product of two vectors
    cross(other) {
      const x = this.y * other.z - this.z * other.y;
      const y = this.z * other.x - this.x * other.z;
      const z = this.x * other.y - this.y * other.x;
      return new Vector3(x, y, z);
    }
  
    // Method to add two vectors
    add(other) {
      return new Vector3(this.x + other.x, this.y + other.y, this.z + other.z);
    }
  
    // Method to subtract two vectors
    subtract(other) {
      return new Vector3(this.x - other.x, this.y - other.y, this.z - other.z);
    }
  
    // Method to multiply the vector by a scalar
    multiply(scalar) {
      return new Vector3(this.x * scalar, this.y * scalar, this.z * scalar);
    }
  
    // Method to divide the vector by a scalar
    divide(scalar) {
      return new Vector3(this.x / scalar, this.y / scalar, this.z / scalar);
    }
  }