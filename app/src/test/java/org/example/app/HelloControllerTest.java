package org.example.app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class HelloControllerTest {

  @Test
  void helloReturnsGreeting() {
    assertEquals("Hello, world!", new HelloController().hello());
  }
}
