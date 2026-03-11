import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import Topics from "../fixtures/topic-fixtures";

acceptance("Animated avatars topic tests", function (needs) {
  needs.pretender((server, helper) => {
    const topicPath = "/t/1000.json";
    const topicResponse = Topics[topicPath];
    server.get(topicPath, () => helper.response(topicResponse));
  });

  test("does not have animated class with no animated avatar", async function (assert) {
    await visit("/t/-/280");
    assert
      .dom(".animated-avatar")
      .doesNotExist("does not add an animated-avatar class");
  });

  test("has animated class when animated avatar", async function (assert) {
    await visit("/t/-/1000");
    assert.dom(".animated-avatar").exists("adds an animated-avatar class");
  });
});
