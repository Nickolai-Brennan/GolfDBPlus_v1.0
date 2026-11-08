import base64
import gzip
import json
import unittest
from unittest.mock import patch

from pga_tour_api import PgaApi, PgaApiError


class PgaApiTests(unittest.TestCase):
    def test_decompress(self):
        source = {"players": [{"id": "1"}]}
        payload = base64.b64encode(gzip.compress(json.dumps(source).encode())).decode()
        self.assertEqual(PgaApi.decompress(payload), source)

    def test_unknown_operation(self):
        with self.assertRaises(PgaApiError):
            PgaApi._query_text("DefinitelyNotAnOperation")

    def test_current_tournament(self):
        api = PgaApi(min_interval=0)
        with patch.object(
            api,
            "config",
            return_value={"defaultTournaments": {"R": [{"leaderboardId": "R2026030"}]}},
        ):
            self.assertEqual(api.current_tournament(), "R2026030")


if __name__ == "__main__":
    unittest.main()
