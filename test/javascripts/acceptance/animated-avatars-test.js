import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";
import Topics from "../fixtures/topic-fixtures";

["enabled", "disabled"].forEach((postStreamMode) => {
  acceptance(
    `Animated avatars topic tests (glimmer_post_stream_mode = ${postStreamMode})`,
    function (needs) {
      needs.pretender((server, helper) => {
        const topicPath = "/t/1000.json";
        const topicResponse = Topics[topicPath];
        server.get(topicPath, () => helper.response(topicResponse));
      });
      needs.settings({
        glimmer_post_stream_mode: postStreamMode,
      });

      test("does not have animated class with no animated avatar", async function (assert) {
        await visit("/t/-/280");
        assert.notOk(
          exists(".animated-avatar"),
          "adds an animated-avatar class"
        );
      });

      test("has animated class when animated avatar", async function (assert) {
        await visit("/t/-/1000");
        assert.ok(exists(".animated-avatar"), "adds an animated-avatar class");
      });
    }
  );
});
